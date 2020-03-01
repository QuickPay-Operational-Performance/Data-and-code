            
import pandas as pd
import numpy as np

def filter_naics_code(path):
    eligible_naics=['3366','1153','5612','3162','2379',\
                    '3159','5629','3149','2362','4831','6114',\
                    '3112','4812','4247','5311','3169','3333','3329','5415','3325']
    chunk_list=[]
    for chunk in pd.read_csv(path, chunksize=10000):
        chunk_list.append(chunk[(chunk.naics_code.astype(str).apply(lambda x: x[0:4]).isin(eligible_naics))\
                                &(chunk.type_of_contract_pricing_code=='J')\
                                &(chunk.small_disadvantaged_business=='f')\
                                &((chunk.contract_bundling_code.fillna('').isin(['H','D']))\
                                  |(chunk.contract_bundling_code.isnull()))])
    filtered_df=pd.concat(chunk_list) #returns the dataframe 
    return filtered_df

def naics_filter_multiple_csvs(path_to_folder):
    import glob, os
    all_files = glob.glob(os.path.join(path_to_folder, "*.csv"))  
    # create a list of path for each file in the folder
    df_from_each_file = (filter_naics_code(f) for f in all_files)
    # query each file in the folder and save as generator
    df = pd.concat(df_from_each_file, ignore_index=True)
    # convert to dataframe 
    return df

def filter_file(path,column_name,column_value):
    chunk_list=[]
    for chunk in pd.read_csv(path, chunksize=10000):
        chunk_list.append(chunk[chunk[column_name]== column_value])
    filtered_df=pd.concat(chunk_list) #returns the dataframe 
    return filtered_df

# chunk size: number of rows to read at a time
# path: location of the raw data file 
# column_name and column_value: specify the condition
# eg., column_name='contracting_officers_determination_of_business_size_code'
#    column_value='S'
# Read 10,000 rows at a time and remove the rows that don't meet the condition
# Keep  and append the remaining in a list
# When the file has been read completely, the chunks are concatenated into a dataframe

def filter_file_query(path,query_detail):
        chunk_list=[]
        for chunk in pd.read_csv(path, chunksize=10000): 
            chunk_list.append(chunk.query(query_detail,engine='python'))
        filtered_df=pd.concat(chunk_list) #returns the dataframe 
        return filtered_df
# we can use python queries if filtering on more than one column
# example: 
# query_detail = "contracting_officers_determination_of_business_size_code=='S' & small_disadvantaged_business=='t'"
 
def query_multiple_csvs(path_to_folder,query_detail):
    import glob, os
   # path_to_folder = '/Users/vibhutidhingra/Downloads/FY2011_All_Contracts_Full_20200110'                   
    all_files = glob.glob(os.path.join(path_to_folder, "*.csv"))  
   # create a list of path for each file in the folder
    df_from_each_file = (filter_file_query(f,query_detail) for f in all_files)
    # query each file in the folder and save as generator
    df = pd.concat(df_from_each_file, ignore_index=True)
    # convert to dataframe 
    return df

def create_combined_prime_id(df): # input dataframe
    df = df.copy(deep=True) #copy so that the input dataframe is not altered
    if {'prime_award_piid','prime_award_parent_piid'}.issubset(df.columns):#if subawards file
        df[['prime_award_piid','prime_award_parent_piid']]=df[['prime_award_piid','prime_award_parent_piid']].astype(str)
        df[['prime_award_piid','prime_award_parent_piid']]=df[['prime_award_piid','prime_award_parent_piid']].replace('nan', np.nan)
        df["combined_id_prime_contract"]=df.prime_award_piid.str.zfill(4).fillna('')+'_'+df.prime_award_parent_piid.str.zfill(4).fillna('')
        return df
    elif {'award_id_piid','parent_award_id'}.issubset(df.columns):#if transactions file
        df[['award_id_piid','parent_award_id']]=df[['award_id_piid','parent_award_id']].astype(str)
        df[['award_id_piid','parent_award_id']]=df[['award_id_piid','parent_award_id']].replace('nan', np.nan)
        df["combined_id_prime_contract"]=df.award_id_piid.str.zfill(4).fillna('')+'_'+df.parent_award_id.str.zfill(4).fillna('')
        return df
    else: print('cannot find relevant columns')

def convert_to_date_time(df): # input dataframe
    df = df.copy(deep=True)#copy so that the input dataframe is not altered
    date_cols=df.columns[df.columns.str.endswith('_date')].tolist() #get columns that have dates
    if date_cols: #If the list is non-empty, execute the following code
        df[date_cols]=df[date_cols].apply(pd.to_datetime, errors='coerce')
        #pandas requires dates to be in some range, coercing errors will set weird dates like year 2919 to NaT
        #Run pd.Timestamp.max and pd.Timestamp.min to see range allowed
    return df

def clean_text_columns(df):
    df = df.copy(deep=True)#copy so that the input dataframe is not altered
    ends_with=('_country','_city','_state','_name', '_description','_contract_pricing')
    text_cols=df.columns[df.columns.str.endswith(ends_with)].tolist()
    if text_cols: #if list is non-empty
        df[text_cols]=df[text_cols].astype(str) #convert values to string
        df[text_cols]=df[text_cols].apply(lambda x: x.str.replace('"', ''))
        # removes quotation from each element in these columns
        df[text_cols]=df[text_cols].applymap(lambda x: " ".join(x.split())) 
        # removes whitespace from each element in these columns, applymap works element-wise
        df[text_cols] = df[text_cols].replace('nan', np.nan) #convert nan strings back to Null
    return df

def calculate_delays(df):#,path_to_dictionary_csv):
    df=df.copy(deep=True)#copy so that the input dataframe is not altered
    ###########################
    # Clean transactions file #
    ###########################
    df=df.drop_duplicates()
    df=clean_text_columns(df)
    df=convert_to_date_time(df)
    if not 'contract_award_unique_key' in set(df.columns): # if column does not exist
        df=create_combined_prime_id(df)    
        id_name='combined_id_prime_contract'
    else: 
        id_name='contract_award_unique_key'
    ##############
    # Get Delays #
    ##############
    df_subset_earliest=df.sort_values(by='action_date').drop_duplicates(subset=id_name)
    # get columns corresponding to earliest action date for each contract
    df_subset_earliest=df_subset_earliest.rename(columns={'period_of_performance_current_end_date':'initial_end_date'})
    # rename completion date column to denote the initial end date of the project
    df_subset_earliest=df_subset_earliest[[id_name,'initial_end_date']]

    df_subset_latest=df.sort_values(by='action_date',ascending=False).drop_duplicates(subset=id_name)
    # get columns corresponding to latest action date for each contract
    df_subset_latest=df_subset_latest.rename(columns={'period_of_performance_current_end_date':'eventual_end_date'})
    # rename completion date column to denote the eventual end date of the project
    df_subset_latest=df_subset_latest[[id_name,'eventual_end_date']]

    delays_df=pd.merge(df_subset_latest,df_subset_earliest,on=id_name)
    delays_df["days_of_change_in_deadline_overall"]=(delays_df.eventual_end_date-delays_df.initial_end_date).dt.days
    
    return delays_df

def calculate_percentage_delays(df):#,path_to_dictionary_csv):
    df=df.copy(deep=True)#copy so that the input dataframe is not altered
    ###########################
    # Clean transactions file #
    ###########################
    df=df.drop_duplicates()
    df=clean_text_columns(df)
    df=convert_to_date_time(df)
    if not 'contract_award_unique_key' in set(df.columns): # if column does not exist
        df=create_combined_prime_id(df)    
        id_name='combined_id_prime_contract'
    else: 
        id_name='contract_award_unique_key'
    ##############
    # Get Delays #
    ##############
    df_subset_earliest=df.sort_values(by='action_date').drop_duplicates(subset=id_name)
    # get columns corresponding to earliest action date for each contract
    df_subset_earliest=df_subset_earliest.rename(columns={'period_of_performance_current_end_date':'initial_end_date',\
                                                          'period_of_performance_start_date':'initial_start_date'})

    # rename completion date column to denote the initial end date of the project
    df_subset_earliest=df_subset_earliest[[id_name,'initial_end_date','initial_start_date']]

    df_subset_latest=df.sort_values(by='action_date',ascending=False).drop_duplicates(subset=id_name)
    # get columns corresponding to latest action date for each contract
    df_subset_latest=df_subset_latest.rename(columns={'period_of_performance_current_end_date':'eventual_end_date'})
    # rename completion date column to denote the eventual end date of the project
    df_subset_latest=df_subset_latest[[id_name,'eventual_end_date']]

    delays_df=pd.merge(df_subset_latest,df_subset_earliest,on=id_name)
    delays_df["days_of_change_in_deadline_overall"]=(delays_df.eventual_end_date-delays_df.initial_end_date).dt.days
    delays_df["initial_completion_time_in_days"]=(delays_df.initial_end_date-delays_df.initial_start_date).dt.days
    delays_df["eventual_completion_time_in_days"]=(delays_df.eventual_end_date-delays_df.initial_start_date).dt.days
    delays_df["percentage_delays"]=(delays_df.eventual_completion_time_in_days-delays_df.initial_completion_time_in_days)*100/delays_df.initial_completion_time_in_days
    return delays_df

# The function below also replaces NaN with values unlike R -- use with caution 
def winsorize_columns(df,column_name,limits_to_set):
    from scipy.stats import mstats
    df_winsorized=df.copy(deep=True)
    #copy so that the input dataframe is not altered
    df_winsorized[column_name+'_'+'winsorized']=mstats.winsorize(df_winsorized[column_name],limits=[limits_to_set,limits_to_set])
    return df_winsorized

def assign_broad_pricing_code(df):
    df = df.copy(deep=True) #copy so that the input dataframe is not altered
    if {'type_of_contract_pricing_code'}.issubset(df.columns):
        df.loc[df.type_of_contract_pricing_code.isin(['A','B','J','K','L','M']),"price_structure"]='FIXED PRICE'
        df.loc[df.type_of_contract_pricing_code.isin(['R','S','T','U','V']),"price_structure"]='COST PRICE'
        df.loc[df.type_of_contract_pricing_code=='Y',"price_structure"]='TIME AND MATERIALS'
        df.loc[df.type_of_contract_pricing_code=='Z',"price_structure"]='LABOUR HOURS'
    return df