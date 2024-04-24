# GameServerAPI-ServerGodot

This Godot game server integrates with the [GameServerAPI](https://github.com/robert-caulfield/GameServerAPI) to manage its lifecycle, authenticate players, and update data like player counts.

 A Game Client implementation in Godot can be found [here](https://github.com/robert-caulfield/GameServerAPI-ClientGodot).

## Key Features

### Game Server Management
- **Server Registration**: Automatically registers the game server with the GameServerAPI on startup, using credentials provided via runtime arguments.
- **Player Authentication**: Validates players via API request using PlayerJoinTokens when they attempt to join the game server, ensuring they are authenticated and authorized to play.
- **Data Updates**: Regularly updates player counts and server status through the API.

### Runtime Configuration
- **Server Authentication and Initialization**: Provides options to set the server name, port, and authentication credentials via runtime arguments or editable script variables.

### Simple Environment
- Provides a simple 3D environment where players are able to move around, labeled with their username.

## Installation Guide
<details>
<summary><strong>Installation Guide</strong></summary>
<p>
 
1. **Download the Source Code**
   - Visit the GitHub repository at `https://github.com/robert-caulfield/GameServerAPI-ServerGodot`.
   - Click on `Code` and select `Download ZIP`, or clone the repository using:
     ```
     git clone https://github.com/robert-caulfield/GameServerAPI-ServerGodot
     ```

2. **Open the Project in Godot**
   - Open the Godot Engine.
   - Select `Import Project` from the Godot Project Manager.
   - Navigate to the downloaded directory and select the `project.godot` file.
   - Click `Import & Edit` to open the project.

3. **Configure Credentials and Game Server Information**:
   - Navigating to `Project > Project Settings > Editor > Run`, and set the credentials, port, and name of the game server based on the needs of your project.

     **Example Runtime Arguments**:
     `
     --username=Admin --password=Admin123$ --port=6545 --server_name="Game Server"
     `
     
     Login information can also be provided in `SignIn.gd`:
     
     ```gdscript
     var username := ""
     var password := ""
     ```
     
   - Additional game server information can be modified in `GameServer.gd`:
     ```gdscript
     # Server Info
     const DEFAULT_PORT = 6545 # What port is set to if none is defined in arguments
     const DEFAULT_SERVER_IP = "127.0.0.1" # What ip is set to if public ip is not fetched
     const MAX_CONNECTIONS = 8 # Max players
     const DEFAULT_SERVER_NAME = "Server" # Name of the server if none is defined in arguments
     const PLAYER_AUTH_TIMEOUT = 10.0 # Time in seconds that a player has to authenticate
     const HEARTBEAT_INTERVAL = 30 # Time in seconds that a heartbeat is sent
     ```

3. **Configure the API Endpoint**
   - Navigate to the `api_helper.gd` script in the Godot Editor.
   - Locate the `API_URL` variable and set it to the correct endpoint URL for your GameServerAPI:
     ```gdscript
     # Base url to api
     const API_URL = "https://localhost:7242/api/"
     ```
   - Save the script.

4. **Run the Project**
   - Ensure the API is running, and run the project.

</p>
</details>

## Technologies Used
- Godot v4.21
