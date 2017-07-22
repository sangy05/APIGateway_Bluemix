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
import Foundation

public class CustomMiddleware: RouterMiddleware {
  
  typealias JSONDictionary = [String: Any]
  var dataHandler:IRUDataHandler?
  var userDatahandler:IRUDataHandler?
  var deviceDatahandler:IRUDataHandler?
  var bookDatahandler:IRUDataHandler?
  //MARK: Manadatory Default Methods :
  // to make this class to be initialized outside the module
  public init() {
    self.dataHandler = IRUDataHandler(dBName: nil)
    self.userDatahandler = IRUDataHandler(dBName: "user") //<Repalce with DB name>
    self.deviceDatahandler = IRUDataHandler(dBName: "device_info") //<Repalce with DB name>
    self.bookDatahandler = IRUDataHandler(dBName: "book") //<Repalce with DB name>
  }
  
  // Default protocol method to be added to use any custom middleware
  public func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) {
    next()
  }
  
  //MARK: Custom Handler Methods
  
  public func testConnection(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) {
    do{
      try response.send("Test API").end()
    }
    catch{
      
    }
    next()
  }
  
  public func reportInvalidURL(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) {
    
    let inputUrl = request.parameters["urlString"] ?? "nil"
    self.deviceDatahandler!.readAllData { (allDocuments, error) in
      if(error == nil){
        
         let inputForUpdate = self.documentIDForDeviceEntryUpdate(inputUrl: inputUrl, fromResult: allDocuments)
        var newInput = JSON(["status":"down"]);
        if var originalData = inputForUpdate.2 {
          originalData["status"] = "down";
          newInput = originalData
        }
        self.deviceDatahandler!.updateDoc(documentID: inputForUpdate.0 ?? "nil", revisionID: inputForUpdate.1 ?? "nil", userData: newInput, onUpdateSuccess: { (message, erorr) in
          do{
            if(error == nil){
                next()
            }
            else{
              try response.send("Failed").end()
            }
          }
          catch{
            //Catch Error
          }
         
        })
        
      }
      else{
        //handle error
      }
    }
  }
  
  
  public func updateDeviceEntry(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) {
    
    let deviceID = request.parameters["deviceID"] ?? "nil"
  
    self.deviceDatahandler!.readAllData { (allDocuments, error) in
      if(error == nil){
        let inputForUpdate = self.documentForDeviceEntry(deviceID: deviceID, fromResult: allDocuments)
        
        var newInput = JSON([:]);
        do {
          let postDataString = try request.readString()
          let updatedDataInJson = JSON.parse(string:postDataString!)
          newInput = updatedDataInJson
        }
        catch{
          // newInput Doesn't change
        }
        
        self.deviceDatahandler!.updateDoc(documentID: inputForUpdate.0 ?? "nil", revisionID: inputForUpdate.1 ?? "nil", userData: newInput, onUpdateSuccess: { (message, erorr) in
          do{
            if(error == nil) {
              try response.send("Record Added Success:" + message.description).end()
            }
            else{
              try response.send("Failed").end()
            }
          }
          catch {
            //Catch Error
          }
        })
        
      }
      else{
        //handle error
      }
    }
  }
  
  public func getEntries(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) {
    
    let dbType = request.parameters["type"] ?? "user"
    var dataHandler = self.userDatahandler!
    
    if(dbType == "user") {
      dataHandler = self.userDatahandler!
    }
    else if(dbType == "device") {
      dataHandler = self.deviceDatahandler!
    }
    else if(dbType == "book") {
      dataHandler = self.bookDatahandler!
    }
    
    dataHandler.readAllData(onFetchSucess: {(result: JSON,error: Error?) in
      do{
        var resultToResponse:JSON?
        if(dbType == "user") {
          resultToResponse = self.filteredDataForUser(fromResult: result)
        }
        else if(dbType == "device") {
          resultToResponse = self.filteredDataForDevice(fromResult: result)
        }
        else if(dbType == "book") {
          resultToResponse = self.filteredData(fromResult: result)
        }
        
        try response.send(resultToResponse!.description).end()
      }
      catch  {
        Log.info("Error Sending Response")
      }
    })
    next()
  }
  
  public func getServerDetails(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) {
    
    let serviceType = request.parameters["serviceType"] ?? "book" //default Book
    var dataHandler = self.userDatahandler!
    
    dataHandler = self.deviceDatahandler!
    
    dataHandler.readAllData(onFetchSucess: {(result: JSON,error: Error?) in
      do{
        
        let dataSet = self.filteredDataForDevice(fromResult: result)
        
        let resultToResponse = self.findServerForService(type: serviceType, fromResult: dataSet)
        try response.send(resultToResponse.description).end()
      }
      catch  {
        Log.info("Error Sending Response")
      }
    })
    next()
  }
  
  
  public func checkDeviceEntry(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) {
    
    let deviceID = request.parameters["deviceID"] ?? "nil"
    
    self.deviceDatahandler!.readAllData(onFetchSucess: {(result: JSON,error: Error?) in
      do{
        
        let dataSet = self.filteredDataForDevice(fromResult: result)
        
        let resultToResponse = self.checkForEntryExistance(deviceID: deviceID, fromResult: dataSet)
        try response.send(resultToResponse.description).end()
      }
      catch  {
        Log.info("Error Sending Response")
      }
    })
    next()
  }

  
  public func createData(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) {
    Log.verbose("\n########\n")
    Log.verbose("Entering createAndSaveData Method")
    Log.verbose("\n########\n")
    
    let dbType = request.parameters["type"] ?? "book"
    var dataHandler = self.bookDatahandler!
    
    if(dbType == "user") {
      dataHandler = self.userDatahandler!
    }
    else if(dbType == "device") {
      dataHandler = self.deviceDatahandler!
    }
    
    do {
      let postDataString = try request.readString()
      let dataInJson = JSON.parse(string:postDataString!)
      
      dataHandler.createDoc(userData:dataInJson, onCreateSuccess: {(result: JSON,error: Error?) in
        do{
          Log.verbose("\n########\n")
          Log.verbose("Try to send final response")
          Log.verbose("\n########\n")
          try response.send("Record Added Success:" + result.description).end()
        }
        catch {
          Log.verbose("\n########\n")
          Log.verbose("Error: Try to send final response:")
          Log.verbose("\n########\n")
        }
        next()
      })
      
    } catch {
      Log.verbose("\n########\n")
      Log.verbose("Error : Reading PostData")
      Log.verbose("\n########\n")
    }
  }
  
  
  //MARK: Utility Methods
  // Core functions

  func documentIDForDeviceEntryUpdate(inputUrl:String, fromResult dbResult:JSON) -> (String?,String?,JSON?) {
    
    var docInfo:(String?,String?,JSON?)
    for eachItem:JSON in dbResult["rows"].arrayValue {
      let document = JSON(eachItem["doc"].dictionaryValue)
      
      if (inputUrl == document["URL"].stringValue) {
        docInfo = (document["_id"].string,document["_rev"].string,document)
        break;
      }
    }
    return docInfo
  }
  
  func documentForDeviceEntry(deviceID:String, fromResult dbResult:JSON) -> (String?,String?,JSON?) {
    var docInfo:(String?,String?,JSON?)
    for eachItem:JSON in dbResult["rows"].arrayValue {
      let document = JSON(eachItem["doc"].dictionaryValue)
      
      if (deviceID == document["deviceID"].stringValue) {
        docInfo = (document["_id"].string,document["_rev"].string,document)
        break;
      }
    }
    return docInfo
  }

  
  func filteredData(fromResult dbResult:JSON) -> JSON {
    var filteredDataInArray = Array<[String:String]>();
    
    for eachItem:JSON in dbResult["rows"].arrayValue {
      let document = JSON(eachItem["doc"].dictionaryValue)
      var filteredDataDocument = [String:String]()
      filteredDataDocument["BookNo"] = document["BookNo"].stringValue
      filteredDataDocument["Name"] = document["Name"].stringValue
      filteredDataDocument["Author"] = document["Author"].stringValue
      
      filteredDataInArray.append(filteredDataDocument)
    }
    
    return JSON(["data":filteredDataInArray])
  }

  
  func filteredDataForDevice(fromResult dbResult:JSON) -> JSON {
    var filteredDataInArray = Array<[String:String]>();
    
    for eachItem:JSON in dbResult["rows"].arrayValue {
      let document = JSON(eachItem["doc"].dictionaryValue)
      var filteredDataDocument = [String:String]()
      filteredDataDocument["serviceType"] = document["serviceType"].stringValue
      filteredDataDocument["URL"] = document["URL"].stringValue
      filteredDataDocument["deviceID"] = document["deviceID"].stringValue
      filteredDataDocument["status"] = document["status"].stringValue
      
      filteredDataInArray.append(filteredDataDocument)
    }
    
    return JSON(["data":filteredDataInArray])
  }
  
  
  func filteredDataForUser(fromResult dbResult:JSON) -> JSON {
    var filteredDataInArray = Array<[String:String]>();
    
    for eachItem:JSON in dbResult["rows"].arrayValue {
      let document = JSON(eachItem["doc"].dictionaryValue)
      var filteredDataDocument = [String:String]()
      filteredDataDocument["userName"] = document["userName"].stringValue
      filteredDataDocument["password"] = document["password"].stringValue
      
      filteredDataInArray.append(filteredDataDocument)
    }
    
    return JSON(["data":filteredDataInArray])
  }
  
  
  //Core service finding algorithm - May be enhanced
  func findServerForService(type:String, fromResult dbResult:JSON) -> JSON {
    var filteredDataDocument = [String:String]()
    for eachItem:JSON in dbResult["data"].arrayValue {
      //pick the first available & allot
      
      if((type == eachItem["serviceType"].stringValue) && ("available" == eachItem["status"].stringValue)) {
        filteredDataDocument["ip"] = eachItem["URL"].stringValue
        filteredDataDocument["forType"] = type
        
        break;
      }
    }
    return JSON(filteredDataDocument)
  }
  
  
  
  func checkForEntryExistance(deviceID:String, fromResult dbResult:JSON) -> JSON {
    
    var filteredDataDocument = ["entryAvailable":"false"]
    
    for eachItem:JSON in dbResult["data"].arrayValue {
      if (deviceID == eachItem["deviceID"].stringValue) {
        filteredDataDocument["entryAvailable"] = "true"
        break;
      }
      
    }
    return JSON(filteredDataDocument)
  }

  
}
