# --- Michael's Custom Commands ---

# Update system and specifically update my Flatpaks
update-rig:
    echo "Updating System..."
    ujust update
    echo "Updating Flatpaks..."
    flatpak update -y

# Quick fix for audio if the G6 acts up
fix-audio:
    systemctl --user restart pipewire wireplumber
    echo "Audio stack restarted."

# Set my preferred fan curve (Example wrapper for LACT)
cool-fans:
    sudo lact api set_fan_control_mode static
    sudo lact api set_fan_static_speed 0.7