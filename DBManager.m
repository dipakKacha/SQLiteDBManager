//
//  DBManager.m
//  mPiler
//
//  Created by Harikrishna on 17/05/16.
//  Copyright © 2016 Harikrishna. All rights reserved.
//

#import <sqlite3.h>

#import "DBManager.h"

@interface DBManager ()

@property (nonatomic, strong) NSString *documentDirectory;
@property (nonatomic, strong) NSString *databaseFileName;
@property (nonatomic, strong) NSMutableArray *arrResult;

- (void)copyDatabaseIntoDocumentsDirectory;
- (void)runQuery:(const char *)query isQueryExecutable:(BOOL)isQueryExecutable;
@end

@implementation DBManager

- (instancetype)initWithDatabaseFileName:(NSString *)dbFileName
{
    self = [super init];
    if(self)
    {
        // Set the documents directory path to the documentsDirectory property.
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        self.documentDirectory = [paths objectAtIndex:0];
        
        // Keep the database file name
        self.databaseFileName = dbFileName;
        
        // Copy the database file into the document directory if needed
        [self copyDatabaseIntoDocumentsDirectory];
        
    }
    return self;
}

// Method to copy the database file into the document directory if required
- (void)copyDatabaseIntoDocumentsDirectory
{
    NSString *destinationPath = [self.documentDirectory stringByAppendingPathComponent:self.databaseFileName];
    if(![[NSFileManager defaultManager] fileExistsAtPath:destinationPath])
    {
        //the database file does not exist in the document directory, so copy it from the main bundle
        NSString *sourcePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:self.databaseFileName];
        NSError *error;
        
        [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:&error];
        
        NSLog(@"Path: %@",destinationPath);
        // Check if any error occurred during copying and display it.
        if (error != nil) {
            NSLog(@"%@", [error localizedDescription]);
        }
    }
}

// Method to get data from database
- (NSArray *)loadDataFromDB:(NSString *)query
{
    // Run the query and indicate that is not executable.
    // The query string is converted to a char* object.
    [self runQuery:[query UTF8String] isQueryExecutable:NO];
    
    // Returned the loaded results.
    return (NSArray *)self.arrResult;
}

// method to insert/update/delete data to database
-(void)executeQuery:(NSString *)query{
    // Run the query and indicate that is executable.
    [self runQuery:[query UTF8String] isQueryExecutable:YES];
}


- (void)runQuery:(const char *)query isQueryExecutable:(BOOL)isQueryExecutable
{
    sqlite3 *sqlite3Database;
    
    //Set the database file path
    NSString *databasePath = [self.documentDirectory stringByAppendingPathComponent:self.databaseFileName];
    
    //Initialize the result array
    if(self.arrResult != nil)
    {
        [self.arrResult removeAllObjects];
        self.arrResult = nil;
    }
    self.arrResult = [[NSMutableArray alloc] init];
    
    //Initialize the column names array
    if(self.arrColumnName != nil)
    {
        [self.arrColumnName removeAllObjects];
        self.arrColumnName = nil;
    }
    self.arrColumnName = [[NSMutableArray alloc] init];
    
    //Open the database
    if(sqlite3_open([databasePath UTF8String], &sqlite3Database) == SQLITE_OK)
    {
        //Declare sqlite3_stmt object in which will be stored the query after having been compiled into SQLite statemetn.
        sqlite3_stmt *compiledStatement;
        
        //Load all data from database to memory
        if(sqlite3_prepare_v2(sqlite3Database, query, -1, &compiledStatement, NULL) == SQLITE_OK)
        {
           //Check if query is non-executable
            if(!isQueryExecutable)
            {
                //In this case data must be loaded from database
                
                //Declare array to keep the data for  each fetched row
                NSMutableDictionary *dicDataRow;
                
                //Loop through the results and add them to the results array row by row
                while (sqlite3_step(compiledStatement) == SQLITE_ROW)
                {
                    // Initialize the mutable array that will contain the data of a fetched row
                    dicDataRow = [[NSMutableDictionary alloc] init];
                    
                    //Get the total number of columns
                    long totalColumns = sqlite3_column_count(compiledStatement);
                    
                    //Go through all columns and fetch all column data
                    for(int i=0 ; i<totalColumns ; i++)
                    {
                        char *dbDataAsChars;
                        //Keep the current column name

                        if(self.arrColumnName.count != totalColumns) {
                            dbDataAsChars = (char *)sqlite3_column_name(compiledStatement, i);
                            [self.arrColumnName addObject:[NSString stringWithUTF8String:dbDataAsChars]];
                        }

                        //Convert column data to text (characters)
                        dbDataAsChars = (char *)sqlite3_column_text(compiledStatement, i);
                        
                        //if there are contents in the current column (field) then add them to the current row of the array
                        if(dbDataAsChars != NULL) {
                            //Convert the characters to string
                            [dicDataRow setObject:[NSString stringWithUTF8String:dbDataAsChars] forKey:self.arrColumnName[i]];
//                            [dicDataRow addObject:[NSString stringWithUTF8String:dbDataAsChars]];
                        }
                    }
                    // Store each fetched data row in the results array, but first check if there is actually data.
                    if(dicDataRow.count > 0) {
                        [self.arrResult addObject:dicDataRow];
                    }
                }
            }
            // This is the case of an executable querire (insert, update, delete...)
            else
            {
                //Execute the query
//                BOOL executeQueryResults = sqlite3_step(compiledStatement);
                if(sqlite3_step(compiledStatement) == SQLITE_DONE) {
                    //Keep the affected rows
                    self.affectedRows = sqlite3_changes(sqlite3Database);
                    
                    //Keep the last inserted row ID
                    self.lastInsertedRowId = sqlite3_last_insert_rowid(sqlite3Database);
                }
                else {
                    // If could not execute the query show the error message on the debugger.
                    NSLog(@"DB Error: %s", sqlite3_errmsg(sqlite3Database));
                }
            }
        }
        else
        {
            // In the database cannot be opened then show the error message on the debugger.
            NSLog(@"%s", sqlite3_errmsg(sqlite3Database));
        }
        // Release the compiled statement from memory.
        sqlite3_finalize(compiledStatement);
    }
    // Close the database.
    sqlite3_close(sqlite3Database);
}

@end
