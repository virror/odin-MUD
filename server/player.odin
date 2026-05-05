package main

import "core:fmt"
import "core:os"
import "core:encoding/json"

Player_status :: enum {
    Username,
    Password,
    Playing,
    Quitting,
}

Player :: struct {
    socket: i64,
    current_room: int,
    status: Player_status,
    name: string,
}

players: map[i64]Player

players_save :: proc(player: ^Player) {
    if(!os.exists("saves")) {
        os.make_directory("saves")
    }
    path := fmt.aprintf("saves/%s", player.name)
    file, err := os.open(path, os.O_WRONLY | os.O_CREATE | os.O_TRUNC)
    if err != nil {
        fmt.println("Error opening file:", err)
        return
    }
    bepa: [1]Player
    bepa[0] = player^
    data, err2 := json.marshal(bepa)
    if err2 != nil {
        fmt.println("Error marshaling player:", err2)
        return
    }
    os.write(file, data)
    os.close(file)
    delete(path)
}

players_load :: proc(player: ^Player) -> bool {
    fmt.println(player.name)
    path := fmt.aprintf("/saves/%s", player.name)
    data, err := os.read_entire_file_from_filename(path)
    if !err {
        fmt.println("Error reading file:", err)
        return false
    }
    json_data: [1]Player
    error := json.unmarshal(data, &json_data)
    if error != nil {
        fmt.println("Error unmarshaling player:", error)
        return false
    }
    player^ = json_data[0]
    delete(path)
    return true
}