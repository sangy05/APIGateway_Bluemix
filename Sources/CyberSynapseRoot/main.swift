
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

// Initialize HeliumLogger
HeliumLogger.use()
// Create a new router


let startController = StartController()
let router = Router()


//Manage All the API services
let apiManager = APIManager(with:router)
apiManager.addServices()

//start the server with port & url linked to router
startController.startServer(with:router)
