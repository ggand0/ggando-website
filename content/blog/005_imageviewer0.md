+++
title = "I built an image viewer in Rust"
slug = "imageviewer0"
date = 2025-03-31
draft = false

[extra]
thumb = "https://ggando.b-cdn.net/viewskater0_640.jpg"

[taxonomies]
categories = ["blog"]
tags = ["rust", "wgpu", "iced"]
+++

<img src="https://ggando.b-cdn.net/viewskater0_1280.jpg" alt="img0" width="500" style="display: block; margin: auto;"/>

## Motivation
As a deep learning and computer vision engineer, I often find it frustrating to explore unfamiliar, large image datasets. Initially, I hadn’t given much thought to the performance of image viewers because I mostly worked with pre-cleaned benchmark datasets. But as I started working in the industry and began prototyping new models with real-world data, I started feeling the pain of not being able to view large datasets **quickly** and **seamlessly**.

Built-in OS image viewers exist, but they're not designed for browsing ML datasets. For example, **eog** on Linux has clean UI and works fine, but it skips rendering images when I hold the arrow key to navigate through a directory. I guess it's because the rendering part is synchronous. Nautilus also feels sluggish if I try to browse through a directory of lots of images. On macOS, the **Preview** app makes you select all images in a directory just to open them at once, and navigation is still slow. When the dataset is large, I also sometimes sample images and plot them with libraries like **matplotlib**, but honestly no one wants to wrtie code just to view images. You can also create a basic UI with **Streamlit**, but that ends up being a web app running on JavaScript, which is **way slower** than native applications.

So, I decided to develop my own image viewer in **Rust**. The choice was straightforward: I wanted to avoid the slow performance that comes with Python or JavaScript, and didn't want to deal with the complexities of memory management in C++. Rust turned out to be quite intuitive for GUI application development.

## Rust GUI frameworks
There are several GUI frameworks available in Rust for building desktop applications. For beginners like me, I think it's better to go with a major, more stable library like **Iced**, **egui**, or **Tauri**. These frameworks are more likely to have more resources and ongoing maintenance.

I chose **Iced** because it was the first framework where I was able to quickly add initial features like displaying a single image and starting prototyping. I also didn't want to handle **layout calculations myself**; I was planning to implement multiple panes for this image viewer. I found Iced to be developer-friendly. Its APIs are intuitive, and the online community is very active on both GitHub and Discord. **Hector**, the author of Iced, is especially responsive and frequently answers questions on Discord, which really helps a lot. I'm not familiar with egui at all, but it could definitely be a solid choice depending on what you want to build.

Iced employs **Elm Architecture**, which is an architectural pattern for building UIs. You define the state of UI components, and only updates it when there are events. Events are often emitted by user interactions such as mouse clicks. 
In your code, you declare the layout of your app; in Iced these are often widgets wrapped in grid containers in the `view()` method. You also define state changing events in a `Message` enum and `update()`. Then you can already run the app! The framework will handle the rendering based on your states and events.
Initially I wondered if there’s any critical feature missing in Iced to build my app, but I thought I could switch to egui and start over. Interestingly, that moment never came; whenever I got stuck I was able to find the necessary information on **GitHub** or in the **Discord community**. I also referred to how other people are building their codebase (e.g [Halloy](https://github.com/squidowl/halloy) and [Sniffnet](https://github.com/GyulyVGC/sniffnet)).

## Dynamic Caching
<img src="https://ggando.b-cdn.net/vs_cache0.gif" alt="img0" width="500" style="display: block; margin: auto;"/>

Loading images from disk before every rendering (**synchronous image loading**) is slow, so I implemented a **dynamic image caching** mechanism. Since I was looking to make a slider UI similar to emulsion where the user navigates through a list of images left and right, I adopted the **sliding window** type cache (a.k.a. ring cache) that slides along with the currently displayed image.
Structure-wise this is just an array of cached images; the current displayed image is stored at the center element, and you have **N pre-loaded images** towards the left and right end of the cache. When the user presses a navigation key (left or right), the app renders the prev/next cached image from it and then loads a new image asynchronously, inserting it at the beginning or end of the cache to prepare for the next rendering.

This resulted in much faster rendering overall. Initially, I noticed some stuttering and lags on Ubuntu with larger images (e.g. 4K), while my MacBook Pro with Apple M1 chip didn’t show the same issue. This was likely due to the M1 chip’s **unified memory architecture**, whereas my Ubuntu desktop has a discrete GPU, introducing overhead when uploading images to GPU memory. Since Iced uses the **wgpu** backend by default, even with image caching on CPU memory, images still had to be uploaded to the GPU on each render.

This had been a major bottleneck, but I recently resolved it by implementing a **custom event loop** and **GPU-side image caching**. The app now stores a set of `wgpu::Texture` objects in GPU memory, allowing images to be rendered instantly. It currently achieves around **8-10 FPS** when navigating through a directory of **10MB 4K images**. However, this approach introduced a new challenge: high memory usage when handling large images. To address this, I plan to explore using compressed texture formats such as BC7 or ASTC.

## What I Learned
This is also my first solid **open-source project**, and I'm learning day by day. Here are some points I learned by working on the project so far.
### 1. Don't Be Afraid to Fork
Many open-source Rust projects are still **young and experimental** (including Iced), and you might encounter issues more frequently compared to frameworks written in other languages. To address them sometimes it's just easier to **fork their repo** and modify the code by yourself. For example, when I was implementing a feature that detects a file drop (via drag-and-drop) from user, I realized that obtaining the cursor position upon file drop wasn’t supported by Iced because winit (the windowing library Iced uses) didn’t support this. There was an ongoing PR that is yet to be merged, but I really needed to implement this feature so I forked winit to achieve this.

This turned out to be a good decision, because this PR was never merged until a year later. Open-source is a gift and sometimes you can’t really expect the maintainers to add the exact feature you want. You could **save a lot of time** by a changing a few lines in the framework you use to achieve the thing you want. 

### 2. Refactoring in Rust: Easy and Hard
As a **Rust noob** coming from Python, I feel two things;
1. It can be **tedious to please the compiler** because Rust is a pretty strict language; it’s type-driven and sometimes you need to fix 30 errors just to change the type of a field in your Struct, making it more  time consuming for prototyping. I also find it painful to fix borrow checking errors during refactoring because Im still not used to it.

2. **but once it compiles, the code almost always works.** For example, there was a time when I struggled a lot to refactor a set of functions while avoiding **borrow checker errors** in my codebase. I just threw them all to ChatGPT and it returned really weird looking blocks, but it did compile and work. This is a great experience as a Python user, as I usually encounter a bunch of runtime errors every time I do a big refactoring in Python. I’m still figuring this out, but I think you can be a lot more adventurous during refactoring, and keep your code clean.

### 3. Utilize Sandbox Projects
As the codebase grows, it can become **increasingly time-consuming** to change the base structure of your app. You decided to make a breaking change, change lots of lines and by the time you have fixed all of your compiler errors you realize that your new design doesn’t really work. This happened a lot in my case, and I learned to create a **small sandbox project** that has the same fundamental code structure but with a lot of dummy data. You can **focus on refactoring** the core design of your skeleton project this way. Working with a smaller project to test your ideas is also good when you work with AI agents, because their performance tends to deteriorate if the length of your prompt is too long. 

## Takeaways
Building things in **Rust** comes with its challenges, but overall this has been a **very enjoyable project** and I’m having a lot of fun working on it. Here’s my impression of Rust and Iced so far:
- **Rust is not scary**, even if you’re from Python
- **Iced is developer-friendly** and great for prototyping
- **Iced is a solid choice** for high-performance image rendering and complex layouts

I plan to keep improving the app, and add features like **visualizing object detection datasets**. Thank you for reading this post! If you’re curious about the resulting app, here’s a link to the repo: [https://github.com/ggand0/viewskater](https://github.com/ggand0/viewskater). Also, here's the demo video:    
<div style="position:relative;padding-top:56.25%;">
    <iframe width="560" height="315" src="https://www.youtube.com/embed/eSkMOStVaTs?si=cVtjPZs7MWtSXzts" title="YouTube video player" frameborder="0" 
    style="border:0;position:absolute;top:0;left:0;height:100%;width:100%;" 
    allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
</div>

<br />