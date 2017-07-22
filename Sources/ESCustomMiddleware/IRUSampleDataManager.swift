/*
 * Copyright IBM Corporation 2017
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Kitura
import HeliumLogger
import LoggerAPI
import CouchDB
import SwiftyJSON


public class IRUDataHandler {
    
    var database: CouchDB.Database?
    var client:CouchDBClient?
    let defaultDBName = "" //<Repalce with DB Name>
  
  //<Repalce with Clodant Service Credntials>
    init(dBName:String?) {
        let connProperties = ConnectionProperties(
            host: "",  // httpd address
            port: 443,         // httpd port
            secured: true,     // https or http
            username: "",      // admin username
            password: ""       // admin password
        )
        self.client = CouchDBClient(connectionProperties: connProperties)
        if let name = dBName {
            self.createDatabase(dbName:name)
        }
        else {
            self.createDatabase(dbName:defaultDBName)
        }
    }
  
  //MARK:  DB CRUD FUNCTIONS
    
    //Create Database
    func createDatabase(dbName:String) {
        guard let couchDBClient = self.client  else {
            print(">> Error in creating DB.")
            return
        }
        
        couchDBClient.dbExists(dbName) {exists, error in
            if  error != nil {
                print(">> Error in checking DB\(error!).")
            } else {
                if  exists {
                    self.database = couchDBClient.database(dbName)
                }
                else {
                    couchDBClient.createDB(dbName) {db, error in
                        if  error != nil {
                            print(">> Error in creating DB\(error!).")
                            return
                        } else {
                            self.database = db!
                            print("Sucess in creating DB.")
                        }
                    }
                }
            }
        }
    }

    

    
  //Read All
  func readAllData(onFetchSucess: @escaping (_ result: JSON, _ error: Error?)->()){
    
        self.database!.retrieveAll(includeDocuments: true, callback: { (document: JSON?, error: Error?) in
            if let error = error {
                print(">> Error in reading document\(error).")
                
            } else {
                guard let document = document as JSON! else {
                    print(">> Error in reading document\(error!).")
                    return
                }
                onFetchSucess(document,nil)
           }
        })
    }
    
    //Read based on document ID //pass the unique ID . For eg.3e91840c36eee151a2bd4daabf64da45
    func readDocument(docID:String, onFetchSucess: @escaping (_ result: JSON, _ error: Error?)->()){
        
        self.database!.retrieve(docID, callback: { (document: JSON?, error: Error?) in
            if let error = error {
                print(">> Error in reading document\(error).")
                
            } else {
                guard let document = document as JSON! else {
                    print(">> Error in reading document\(error!).")
                    return
                }
                onFetchSucess(document,nil)
            }
        })
    }
    
    //Create
    func createDoc(userData:JSON, onCreateSuccess: @escaping (_ response: JSON, _ error: Error?)->()) {
        
        self.database!.create(userData) {(id: String?, rev: String?, document: JSON?, error: Error?) in
            if (error != nil) {
                
                Log.verbose("\n########\n")
                Log.verbose("Clodant DB thrown error on create")
                Log.verbose("\n########\n")
                //print(">> Error in creating document\(error!).")
            }
            else {
                Log.verbose("\n########\n")
                Log.verbose("success: Data Saved in cloudant")
                Log.verbose("\n########\n")
                onCreateSuccess(document!,nil)
            }
        }
    }
    
    //Update
    func updateDoc(documentID:String, revisionID:String, userData:JSON, onUpdateSuccess: @escaping (_ response: JSON, _ error: Error?)->()) {
        
        self.database!.update(documentID, rev: revisionID, document: userData) { (id: String?, responseDocument: JSON?, error: Error?) in
            if (error != nil) {
                print(">> Error in creating document\(error!).")
                
            }
            else {
                onUpdateSuccess(responseDocument!,nil)
            }
        }
        
    }
    
    //Delete
    func deleteDoc(docID:String, revID:String, onDeleteSuccess: @escaping (_ response: JSON, _ error: Error?)->()) {
        self.database!.delete(docID, rev: revID, callback: { (error:Error?) in
            if (error != nil) {
                print(">> Error in creating document\(error!).")
            }
            else {
                onDeleteSuccess(JSON(docID),nil)
            }
        })
    }
    
    
    // END OF CRUD FUNCTIONS
}
