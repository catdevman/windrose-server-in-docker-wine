FROM cm2network/steamcmd:latest

USER root

# Install all necessary dependencies
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        wine \
        wine32 \
        wine64 \
        libwine \
        libwine:i386 \
        xvfb \
        xauth \
        winbind \
        cabextract \
        wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Manually grab the latest winetricks script
RUN wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
    && chmod +x winetricks \
    && mv winetricks /usr/local/bin/

# Switch back to the secure steam user
USER steam
WORKDIR /home/steam/

# Set up the permanent Wine environment
ENV WINEARCH=win64
ENV WINEDLLOVERRIDES="msvcp140=n,b;vcruntime140=n,b;ucrtbase=n,b"
ENV WINEDEBUG=-all
ENV DISPLAY=:99

# Build the 64-bit prefix and install C++ Runtimes using a temporary virtual display
RUN xvfb-run --auto-servernum winetricks -q vcrun2022

# Copy in our custom startup script
COPY --chown=steam:steam entrypoint.sh /home/steam/entrypoint.sh
RUN chmod +x /home/steam/entrypoint.sh

# Set the script to run when the container starts
ENTRYPOINT ["/home/steam/entrypoint.sh"]
