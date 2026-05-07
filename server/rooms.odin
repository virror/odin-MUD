package main

import "core:fmt"
import "core:strings"

Room :: struct {
    description: string,
    players: map[string]^Player,
    north: int,
    south: int,
    east: int,
    west: int,
}

rooms: [4]Room

rooms_init :: proc() {
    rooms[0] = Room {
        description = "Dummy room.",
    }
    rooms[1] = Room {
        description = "You are in a big hall. There are exits to the north and south.",
        north = 2,
        south = 3,
    }
    rooms[2] = Room {
        description = "You are in a small room. There is an exit to the south.",
        south = 1,
    }
    rooms[3] = Room {
        description = "You are in a dark cave. There is an exit to the north.",
        north = 1,
    }
}

rooms_send :: proc(player: ^Player, message: string) {
    for _, p in rooms[player.current_room].players {
        if p.socket != player.socket {
            send_msg2(p.socket, message)
        }
    }
    delete(message)
}

rooms_move :: proc(player: ^Player, direction: int) -> string {
    current_room := rooms[player.current_room]
    delete_key(&current_room.players, player.name)
    next_room_index: int
    switch direction {
    case 0:
        next_room_index = current_room.north
    case 2:
        next_room_index = current_room.south
    case 1:
        next_room_index = current_room.east
    case 3:
        next_room_index = current_room.west
    }
    if next_room_index == 0 {
        return "You can't go that way."
    }
    player.current_room = next_room_index
    rooms[next_room_index].players[player.name] = player
    return strings.clone(rooms[next_room_index].description)
}