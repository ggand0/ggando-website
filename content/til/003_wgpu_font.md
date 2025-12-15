+++
title = "How to load fonts in wgpu integration with iced"
slug = "wgpu-font"
date = 2025-02-21
draft = false

[taxonomies]
categories = ["til"]
tags = ["rust", "iced"]
+++

I currently use the wgpu integration setup for my image viewer app and needed to load custom fonts (including an icon font) without using a Compositor. In iced 0.13.1, you usually set your fonts via `Settings` and pass it like `application(...).settings(your_settings)`. I found this part in `iced_winit::program:run_action()`, and it seems like it is the `Compositor` that loads fonts in the regular iced setup:
```rust
Action::LoadFont { bytes, channel } => {
    if let Some(compositor) = compositor {
        // TODO: Error handling (?)
        compositor.load_font(bytes.clone());

        let _ = channel.send(Ok(()));
    }
}
```

`iced/graphics/src/compositor.rs`:
```rust
/// Loads a font from its bytes.
fn load_font(&mut self, font: Cow<'static, [u8]>) {
    crate::text::font_system()
        .write()
        .expect("Write to font system")
        .load_font(font);
}
```

Compositor is not accessible in the wgpu integration example because we directly use `Engine` to render things, but it turns out you can directly access the FontSystem like this:
```rust
use std::borrow::Cow;
use iced_wgpu::graphics::text::font_system;

fn register_font_manually(font_data: &'static [u8]) {
    use std::sync::RwLockWriteGuard;

    // Get a mutable reference to the font system
    let font_system = font_system();
    let mut font_system_guard: RwLockWriteGuard<_> = font_system
        .write()
        .expect("Failed to acquire font system lock");

    // Load the font into the global font system
    font_system_guard.load_font(Cow::Borrowed(font_data));
}
```

and call it after the Engine creation in Self::Loading() block:
```rust
let engine = Engine::new(
    &adapter, &device, &queue, format, None);
engine.create_image_cache(&device); // Manually create image cache

// Manually register fonts
register_font_manually(include_bytes!("../assets/fonts/viewskater-fonts.ttf"));
register_font_manually(include_bytes!("../assets/fonts/Iosevka-Regular-ascii.ttf"));
register_font_manually(include_bytes!("../assets/fonts/Roboto-Regular.ttf"));
```
Now you can use icon fonts like before!

## Links
- [iced/winit/src
/program.rs](https://github.com/iced-rs/iced/blob/81ca3d2a223d62fbb48b93dcea5409f6212605fa/winit/src/program.rs#L1536)
- [runtime/src/font.rs](https://github.com/iced-rs/iced/blob/ffc412d6b7f8009c783715c021fc36780f26db36/runtime/src/font.rs#L11)
- [graphics/src/compositor.rs](https://github.com/iced-rs/iced/blob/81ca3d2a223d62fbb48b93dcea5409f6212605fa/graphics/src/compositor.rs#L66)