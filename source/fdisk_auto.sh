#!/bin/bash

# Initialize an empty array to store partition information
partitions=()

# Use fdisk to list partitions and parse the output
while read -r line; do
    # Skip empty lines
    if [ -n "$line" ]; then
        partitions+=("$line")
    fi
done < <(fdisk -l | grep -E 'Disk /dev/')

# Determine the device name of the bootable partition
self_partition="$(df -h / | grep -Eo '/dev/[a-zA-Z0-9]+' | head -1)"

self_index=-1

for ((i=0; i<${#partitions[@]}; i++)); do
    if [[ "${partitions[i]}" == *"${self_partition}:"* ]]; then
        self_index=$i
        break
    fi
done

# Remove the bootable partition from the list
if [ "$self_index" -ne -1 ]; then
    unset "partitions[$self_index]"
fi

# Print the list of partitions to the user
echo "List of partitions:"
for ((i=0; i<${#partitions[@]}; i++)); do
    echo "[$i] ${partitions[i]}"
done

# Ask the user which partition(s) to delete
read -p "Enter the number of the partition(s) to delete (space-separated or 'all' to remove all): " choices

if [ "$choices" == "all" ]; then
    for partition in "${partitions[@]}"; do
        dev_name=$(echo "$partition" | cut -d' ' -f2 | sed 's/:$//')
        fdisk "$dev_name" <<< "d"
    done
else
    choices=($choices)
    for choice in "${choices[@]}"; do
        if [ "$choice" -ge 0 ] && [ "$choice" -lt "${#partitions[@]}" ]; then
            dev_name=$(echo "${partitions[choice]}" | cut -d' ' -f2 | sed 's/:$//')
            fdisk "$dev_name" <<< "d"
        else
            echo "Invalid choice: $choice"
        fi
    done
fi

echo "Partition(s) deleted successfully."
