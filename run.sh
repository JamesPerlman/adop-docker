sudo docker run -it \
    -v /usr/lib/wsl:/usr/lib/wsl \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v /mnt/wslg:/mnt/wslg \
    -e DISPLAY=$DISPLAY \
    -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR \
    -e LIBGL_ALWAYS_SOFTWARE=1 \
    --device=/dev/dxg \
    --gpus all \
    adop
