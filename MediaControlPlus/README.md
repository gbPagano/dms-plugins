# Media Control Plus

A simple extended version of the default media widget from DMS with mainly improved support for vertical layouts while also adding more control over the widgets.

## Features

- Improved Vertical layout settings
  - Can show title in vertical layout, complete with scrollable text option, and optional backdrop behind the title
  - Can set max height for title area in vertical layout
  - Can show next/previous buttons in vertical layout
- Rearrangable widget elements in both horizontal and vertical layouts
- Visualizer settings for both horizontal and vertical layouts
- Rotated visualizer for vertical layout
- Settings for visualizer bar count and width / height
- Settings for visualizer position (top, center, bottom)
- New visualizer style (dotted and line style)
- Option to change the listener for the visualizer to all audio instead of just the media player
- Optional popout size settings for both the horizontal and vertical layouts
- Optional extra backdrop panel behind the media content
- Optional use of the track artwork as a blurred backdrop for the popout content

## IPC

```bash
# Open the media player popout
dms ipc call mediaControlPlus openPopout
# Close the media player popout
dms ipc call mediaControlPlus closePopout
# Toggle the media player popout
dms ipc call mediaControlPlus togglePopout
```

## Some Preview

### Preview

![media control plus - dotted](preview/dotted-style.png)

![media control plus - dotted 2](preview/dotted-style-2.png)

![media control plus - Preview Vertical 1](preview/vertical.png)

![media control plus - Preview Vertical 2](preview/vertical-2.png)

![media control plus - Preview Horizontal](preview/horizontal.png)

![media control plus - Preview Visualizer only](preview/visualizer-only.png)

![media control plus - some setting 1](preview/settings-1.png)

![media control plus - some setting 2](preview/settings-2.png)
