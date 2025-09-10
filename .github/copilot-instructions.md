# EntWatch Discord Integration Plugin - Copilot Instructions

## Repository Overview

This repository contains **EntWatch_Discord**, a SourceMod plugin that integrates with the EntWatch plugin to send ban/unban notifications to Discord channels via webhooks. The plugin monitors EntWatch entity management events and automatically posts formatted notifications to Discord servers.

### Key Components
- **Main Plugin**: `addons/sourcemod/scripting/EntWatch_Discord.sp` - Core plugin source code
- **Build System**: `sourceknight.yaml` - SourceKnight build configuration
- **CI/CD**: `.github/workflows/ci.yml` - Automated build and release pipeline

## Technical Environment

- **Language**: SourcePawn (SourceMod scripting language)
- **Platform**: SourceMod 1.11.0+ (specifically 1.11.0-git6917)
- **Build Tool**: SourceKnight (modern SourceMod build system)
- **Compiler**: SourcePawn compiler (spcomp) via SourceKnight
- **Target Games**: Source Engine games (CS:GO, CS2, TF2, etc.)

## Dependencies and Architecture

### Required Dependencies
The plugin depends on several other SourceMod plugins and libraries:

1. **EntWatch** (`srcdslab/sm-plugin-EntWatch`)
   - Provides entity management and banning system
   - Source of ban/unban events that trigger Discord notifications
   - Includes native functions used by this plugin

2. **RelayHelper** (`srcdslab/sm-plugin-RelayHelper`) 
   - Handles Discord message formatting and sending
   - Provides Steam avatar retrieval functionality
   - Contains common Discord webhook utilities

3. **DiscordWebhookAPI** (`srcdslab/sm-plugin-DiscordWebhookAPI`)
   - Low-level Discord webhook API implementation
   - Handles HTTP requests to Discord endpoints

### Message Types and Discord Integration
The plugin sends two types of Discord notifications:

1. **Ban Notifications** (`Message_Type_Eban`):
   - Triggered by `EntWatch_OnClientBanned`
   - Includes: admin, target, ban length, reason, total ban count, target's Steam avatar
   - Length parameter: positive integer (ban duration)

2. **Unban Notifications** (`Message_Type_Eunban`):
   - Triggered by `EntWatch_OnClientUnbanned` 
   - Includes: admin, target, reason, total ban count, target's Steam avatar
   - Length parameter: -1 (indicates unban operation)

### Discord Message Format
Messages are formatted via RelayHelper and include:
- Rich embed with colored styling
- Target player information with Steam avatar
- Admin information who performed the action
- Ban reason and duration (for bans)
- Link to ban website (if configured via `eban_website` ConVar)
- Total ban count for the target player

## Build System (SourceKnight)

### Configuration
The `sourceknight.yaml` file defines:
- **Project name**: EntWatch_Discord
- **Dependencies**: Automatic download and setup of required plugins
- **Build target**: Single plugin compilation
- **Output**: Compiled `.smx` plugin file

### Building Locally
```bash
# Install SourceKnight if not available
# Run build (typically via GitHub Actions)
# Output will be in .sourceknight/package/addons/sourcemod/plugins/
```

### CI/CD Pipeline
The GitHub Actions workflow (`ci.yml`):
1. **Build**: Compiles plugin using SourceKnight action
2. **Package**: Creates distributable package
3. **Tag**: Creates/updates 'latest' tag on main branch pushes
4. **Release**: Creates GitHub releases with compiled plugin

## Code Style & Standards

### SourcePawn Specific Guidelines
- Use `#pragma semicolon 1` and `#pragma newdecls required`
- Indentation: 4-space tabs
- Global variables: Prefix with `g_` (e.g., `g_Eban`)
- Functions: PascalCase (e.g., `OnClientPostAdminCheck`)
- Local variables: camelCase
- ConVars: Use descriptive names with plugin prefix (e.g., `eban_discord_enable`)

### Plugin Structure Standards
```sourcepawn
// Required pragmas at top
#pragma semicolon 1
#pragma newdecls required

// Includes
#include <EntWatch>
#include <RelayHelper>

// Plugin info block
public Plugin myinfo = { /* ... */ };

// Plugin lifecycle functions
public void OnPluginStart() { /* ... */ }
public void OnClientPostAdminCheck(int client) { /* ... */ }
public void OnClientDisconnect(int client) { /* ... */ }

// Event handlers
public void EntWatch_OnClientBanned(/* ... */) { /* ... */ }
public void EntWatch_OnClientUnbanned(/* ... */) { /* ... */ }
```

## Configuration

### ConVars
The plugin creates these configuration variables:
- `eban_discord_enable` - Toggle notifications on/off (default: 1, range: 0.0-1.0)
- `eban_discord` - Discord webhook URL (protected with FCVAR_PROTECTED)
- `eban_website` - Optional website URL for ban listings (for linking to ban list pages)

### Global Variables
- `g_Eban` - Global_Stuffs structure containing ConVar handles and configuration
- `g_sClientAvatar[client]` - Array storing Steam avatar URLs for connected clients

### Auto-Config
Plugin automatically creates config file via `AutoExecConfig(true, PLUGIN_NAME)` 
Config file: `cfg/sourcemod/EntWatch_Discord.cfg`

## Development Workflow

### Making Changes
1. **Understand the flow**: EntWatch events → This plugin → RelayHelper → Discord
2. **Check dependencies**: Ensure changes are compatible with EntWatch and RelayHelper APIs
3. **Test ConVars**: Verify configuration variables work correctly
4. **Handle late loads**: Plugin supports late loading when players are already connected

### Common Tasks
- **Adding new notification types**: Hook additional EntWatch forwards
- **Modifying message format**: Work with RelayHelper message structures  
- **Adding configuration**: Create new ConVars with appropriate flags
- **Error handling**: Add validation for client indices and ConVar values

### Testing Considerations
- **Discord Integration**: Test with real Discord webhook to verify message formatting and delivery
- **Late Plugin Loading**: Test plugin loading when players are already connected to server
- **Client Management**: Verify proper avatar caching and cleanup on client connect/disconnect
- **ConVar Validation**: Test enable/disable functionality and protected webhook URL handling
- **Event Handling**: Test multiple simultaneous ban/unban events for race conditions
- **Error Cases**: Test with invalid admin indices, disconnected clients, and malformed webhook URLs

### Local Testing Setup
1. Set up a test SourceMod server with required dependencies
2. Create a Discord webhook for testing notifications
3. Configure ConVars with test webhook URL
4. Use EntWatch commands to trigger ban/unban events
5. Monitor Discord channel for properly formatted notifications
6. Check server console for any error messages or warnings

### Plugin Integration Points

### EntWatch Integration
```sourcepawn
// Required forwards to implement
public void EntWatch_OnClientBanned(int admin, int length, int target, const char[] reason)
public void EntWatch_OnClientUnbanned(int admin, int target, const char[] reason)

// Available natives from EntWatch
int EntWatch_GetClientEbansNumber(int client) // Returns total ban count for client
```

### RelayHelper Integration
```sourcepawn
// Initialization in OnPluginStart()
RelayHelper_PluginStart();

// Message sending (ban notification)
SendDiscordMessage(g_Eban, Message_Type_Eban, admin, target, length, reason, ebansNumber, 0, _, avatar);

// Message sending (unban notification) 
SendDiscordMessage(g_Eban, Message_Type_Eunban, admin, target, -1, reason, ebansNumber, 0, _, avatar);

// Steam avatar retrieval
GetClientSteamAvatar(client); // Populates g_sClientAvatar[client]
```

### Key Functions and Logic
- `OnClientPostAdminCheck(int client)` - Retrieves Steam avatar when client connects
- `OnClientDisconnect(int client)` - Clears avatar cache when client leaves
- Client validation: Checks for fake clients, SourceTV, and valid admin indices
- Late load support: Loops through connected clients in OnPluginStart()

## Common Issues and Solutions

### Build Issues
- **Missing dependencies**: SourceKnight automatically downloads them via `sourceknight.yaml`, but verify all repositories are accessible
- **Compilation errors**: Usually indicate API changes in dependencies (EntWatch, RelayHelper, DiscordWebhookAPI)
- **Include path issues**: Dependencies should auto-install to `addons/sourcemod/scripting/include/`
- **Version conflicts**: Ensure SourceMod version matches dependency requirements

### Runtime Issues
- **Webhook not working**: 
  - Check `eban_discord` ConVar is set correctly with valid Discord webhook URL
  - Verify Discord channel permissions allow webhook posts
  - Check server console for HTTP error messages
- **Missing avatars**: 
  - Verify Steam API access and RelayHelper Steam integration
  - Check if `g_sClientAvatar[client]` is being populated correctly
  - Ensure Steam API key is configured if required by RelayHelper
- **Late load problems**: 
  - Plugin handles this via client loop in `OnPluginStart()`
  - Check for proper client validation (not fake, not SourceTV)
- **Events not triggering**:
  - Ensure EntWatch plugin is loaded and functional
  - Verify admin permissions for ban/unban actions
  - Check that `eban_discord_enable` ConVar is set to 1

### Debugging Tips
- Enable SourceMod logging: `sm_logs on`
- Check error logs in `logs/errors_YYYYMMDD.log`
- Use `sm plugins list` to verify plugin is loaded
- Use `sm cvars eban` to check ConVar values
- Monitor Discord webhook delivery via Discord's webhook management interface

### Performance Considerations
- Plugin is event-driven (low overhead)
- Steam avatar caching prevents redundant API calls
- ConVar checks prevent unnecessary processing when disabled

## Security Notes

- Discord webhook URLs are marked `FCVAR_PROTECTED`
- No sensitive data is logged or exposed
- Steam API calls are handled safely via RelayHelper
- All client validation includes proper bounds checking

## Versioning and Releases

- Use semantic versioning (MAJOR.MINOR.PATCH)
- Releases are automated via GitHub Actions
- 'latest' tag is maintained for development builds
- Tagged releases for stable versions

## Getting Started for New Contributors

1. **Fork and clone** the repository
2. **Review dependencies** in `sourceknight.yaml`
3. **Understand the plugin flow** from EntWatch to Discord
4. **Check existing issues** for enhancement opportunities
5. **Test changes** with a real Discord webhook
6. **Follow SourcePawn coding standards** outlined above

## Useful Resources

- [SourceMod API Documentation](https://sm.alliedmods.net/new-api/)
- [EntWatch Plugin Repository](https://github.com/srcdslab/sm-plugin-EntWatch)
- [RelayHelper Plugin Repository](https://github.com/srcdslab/sm-plugin-RelayHelper)
- [SourceKnight Build Tool](https://github.com/maxime1907/sourceknight)
- [Discord Webhook Documentation](https://discord.com/developers/docs/resources/webhook)

## File Structure Reference

```
/
├── .github/
│   ├── workflows/ci.yml          # Build and release automation
│   └── copilot-instructions.md   # This file
├── addons/sourcemod/scripting/
│   └── EntWatch_Discord.sp       # Main plugin source
└── sourceknight.yaml             # Build configuration
```