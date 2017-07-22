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
import ESCustomMiddleware

//HeliumLogger.use()
class APIManager{
  
  var mainRouter:Router?
  init(with mainRouter:Router?) {
    guard let router = mainRouter else{
      return
    }
    self.mainRouter = router
    self.handleError()
  }
  
  func addServices(){
    //DB Operation
    let myMiddleware = CustomMiddleware()
    addCrudServcies(dbMiddleware:myMiddleware)
    
  }
  
  //Add DB CRUD Services
  func addCrudServcies(dbMiddleware:CustomMiddleware){
    //GET
    router.all("/data/*",middleware: dbMiddleware)
    
    //TEst Get Entries
    router.get("/data/test", handler:dbMiddleware.testConnection);
    
    //Get
    router.get("/data/getEntries/:type", handler:dbMiddleware.getEntries)
    router.get("/data/getServer/:serviceType", handler:dbMiddleware.getServerDetails)
    router.get("/data/invalidURL/:serviceType/:urlString", handler:dbMiddleware.reportInvalidURL,dbMiddleware.getServerDetails)
    router.get("/data/checkDevice/:deviceID", handler:dbMiddleware.checkDeviceEntry)
    
    //POST
    router.post("/data/addEntry/:type", handler:dbMiddleware.createData)
    
    //POST
    router.post("/data/updateDeviceEntry/:deviceID", handler:dbMiddleware.updateDeviceEntry)
    
    
  }
  
  //MARK: Error Handler
  func handleError(){
    // Handles any errors that get set
    self.mainRouter!.error { request, response, next in
      response.headers["Content-Type"] = "text/plain; charset=utf-8"
      let errorDescription: String
      if let error = response.error {
        errorDescription = "\(error)"
      } else {
        errorDescription = "Unknown error"
      }
      try response.send("Caught the error: \(errorDescription)").end()
    }
  }
}
