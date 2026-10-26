# VC3D (Volume Cartographer 3D) on an Intel Mac.
# Wraps the official Linux x86_64 AppImage from ScrollPrize/villa releases
# in Ubuntu 24.04; the GUI is drawn on the Mac through XQuartz (X11 over TCP).
FROM ubuntu:24.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      libglvnd0 libglx0 libegl1 libopengl0 libgl1 libgl1-mesa-dri libglx-mesa0 \
      libx11-6 libx11-xcb1 libxcb1 libice6 libsm6 \
      libfontconfig1 libfreetype6 libharfbuzz0b fonts-dejavu-core ca-certificates \
      libxkbcommon-x11-0 libxcb-cursor0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 \
      libxcb-randr0 libxcb-render-util0 libxcb-shape0 libxcb-xinerama0 libxcb-xkb1 \
   && rm -rf /var/lib/apt/lists/*
# Exactly one AppImage must sit next to this Dockerfile (./fetch-appimage.sh puts it there).
COPY VC3D-*-linux-x86_64.AppImage /opt/VC3D.AppImage
RUN chmod +x /opt/VC3D.AppImage
# No FUSE inside containers -> let the AppImage extract itself at start.
# QT_X11_NO_MITSHM: shared memory does not cross the Docker VM boundary.
# QT_XCB_GL_INTEGRATION=none: VC3D draws its viewers without OpenGL; skip Qt's GLX probe.
ENV APPIMAGE_EXTRACT_AND_RUN=1 \
    QT_QPA_PLATFORM=xcb \
    QT_X11_NO_MITSHM=1 \
    QT_XCB_GL_INTEGRATION=none \
    LANG=C.UTF-8
ENTRYPOINT ["/opt/VC3D.AppImage"]
CMD ["VC3D", "--cache-size", "3"]
