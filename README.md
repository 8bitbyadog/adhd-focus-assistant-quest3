# ADHD Focus Assistant (Meta Quest 3 AR)

An augmented reality application designed to help individuals with ADHD manage tasks, maintain focus, and improve productivity using the Meta Quest 3's passthrough capabilities.

## Requirements

- Godot 4.2 or higher
- Meta Quest 3 headset
- OpenXR Plugin (included in Godot)
- XR Tools addon

## Setup Instructions

1. Clone this repository
2. Open the project in Godot 4.2+
3. Install the XR Tools addon:
   - Download from the Godot Asset Library
   - Enable in Project Settings > Plugins
4. Configure your Meta Quest 3:
   - Enable Developer Mode in the Oculus app
   - Enable Hand Tracking in Quest settings
   - Enable Passthrough API access

## Development Setup

1. Connect your Quest 3 via USB
2. Enable USB debugging on the headset
3. In Godot, select "Meta Quest" as the export target
4. Install Android Build Template if prompted

## Project Structure

```
├── scenes/
│   ├── Main.tscn         # Main scene with XR setup
│   ├── UI/               # UI scene components
│   └── Tasks/            # Task management scenes
├── scripts/
│   ├── Core/            # Core functionality
│   └── Interaction/     # User interaction scripts
├── assets/
│   ├── Models/          # 3D models
│   ├── Materials/       # Materials and shaders
│   └── Sounds/          # Audio assets
└── addons/              # XR Tools and other plugins
```

## Features

### Phase 1 (Current)
- [x] Basic passthrough AR setup
- [ ] Hand tracking integration
- [ ] Floating UI system
- [ ] Basic task cards

### Phase 2 (Planned)
- [ ] Task management system
- [ ] Timer implementation
- [ ] Basic focus zone

### Phase 3 (Future)
- [ ] Spatial anchoring
- [ ] Advanced shaders
- [ ] Performance optimization

## Performance Guidelines

- Target Frame Rate: 90 FPS
- Maximum Draw Calls: 100
- Polygon Budget: <1000 per UI element
- Texture Size: 1024x1024 maximum

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

MIT License - See LICENSE file for details 