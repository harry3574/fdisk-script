#!/bin/bash

# Initialize an empty array to store partition information
partitions=()

# Use fdisk to list partitions and parse the output
mapfile -t partitions < <(fdisk -l | awk '/Disk \/dev\// {print $2}' | sed 's/://')

# Determine the device name of the bootable partition
self_partition=$(df -h / | awk 'NR==2 {print $1}')

self_index=-1

for ((i=0; i<${#partitions[@]}; i++)); do
    if [[ "${partitions[i]}" == "$self_partition" ]]; then
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
        fdisk "$partition" <<< "d"
    done
else
    choices=($choices)
    for choice in "${choices[@]}"; do
        if [ "$choice" -ge 0 ] && [ "$choice" -lt "${#partitions[@]}" ]; then
            fdisk "${partitions[choice]}" <<< "d"
        else
            echo "Invalid choice: $choice"
        fi
    done
fi

echo "Partition(s) deleted successfully."
