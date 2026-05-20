package main

import "core:fmt"
import "core:net"
import "core:thread"
import "core:strings"
import "core:nbio"
import "core:container/xar"

IP_ADDRESS :: "127.0.0.1"
PORT :: 8080

Server :: struct {
	socket:      nbio.TCP_Socket,
	connections: xar.Array(Connection, 4),
}

Connection :: struct {
	server: ^Server,
	sock:   nbio.TCP_Socket,
	buf:    [50]byte,
}

server: Server

send_msg2 :: proc(sock: i64, msg: string) {
	send_msg((nbio.TCP_Socket(sock)), msg)
}

send_msg :: proc(sock: nbio.TCP_Socket, msg: string) {
	_, err_send := net.send_tcp(sock, transmute([]u8)msg)
	if err_send != nil {
		fmt.println("Failed to send data")
	}
}

handle_msg :: proc(op: ^nbio.Operation, connection: ^Connection) {
	sock := connection.sock
	player := &players[i64(sock)]

	if op.recv.err != nil {
		fmt.println("Client disconnected")
		player_leave(player, i64(sock))
		nbio.close(sock)	//TODO: Clean up server.connections
		return
	}
	input := string(connection.buf[:op.recv.received])

	switch player.status {
	case Player_status.Username:
		player.name = strings.clone(input)
		player_load(player)
		send_msg(sock, "Enter password:")
		player.socket = i64(sock)
		player.status = Player_status.Password
	case Player_status.Password:
		player.status = Player_status.Playing
		msg := rooms_description(player.current_room, player)
		send_msg(sock, msg)
		delete(msg)
		rooms[player.current_room].players[player.name] = player
	case Player_status.Playing:
		input_handle(sock, input)
	case Player_status.Quitting:
		if input == "yes" {
			send_msg(sock, "Goodbye!")
			player_leave(player, i64(sock))
			nbio.close(sock)	//TODO: Clean up server.connections
			return
		} else if input == "no" {
			send_msg(sock, "Welcome back!")
			player.status = Player_status.Playing
		} else {
			send_msg(sock, "Invalid input. Do you want to quit? (yes/no)")
		}
	}
	nbio.recv_poly(connection.sock, {connection.buf[:]}, connection, handle_msg)
}

on_accept :: proc(op: ^nbio.Operation) {
	fmt.assertf(op.accept.err == nil, "Error accepting a connection: %v", op.accept.err)

	nbio.accept(server.socket, on_accept)

	connection, alloc_err := xar.push_back_elem_and_get_ptr(&server.connections, Connection{
		server = &server,
		sock   = op.accept.client,
	})
	assert(alloc_err == nil)

	nbio.recv_poly(op.accept.client, {connection.buf[:]}, connection, handle_msg)

	players[i64(connection.sock)] = player_create()
	send_msg(connection.sock, "Welcome to the MUD! Please enter your username:")
}

tcp_mud_server :: proc() {
	err := nbio.acquire_thread_event_loop()
	fmt.assertf(err == nil, "Could not initialize nbio: %v", err)
	defer nbio.release_thread_event_loop()

	local_addr, ok := net.parse_ip4_address(IP_ADDRESS)
	if !ok {
		fmt.println("Failed to parse IP address")
		return
	}
	endpoint := nbio.Endpoint {
		address = local_addr,
		port = PORT,
	}
	socket, err2 := nbio.listen_tcp(endpoint)
	if err2 != nil {
		fmt.println("Failed to listen on TCP")
		return
	}
	server.socket = socket
	fmt.printfln("Listening on TCP: %s", nbio.endpoint_to_string(endpoint))

	nbio.accept(socket, on_accept)
	rerr := nbio.run()
	fmt.assertf(rerr == nil, "Server stopped with error: %v", rerr)
}

main :: proc() {
	input_init()
	rooms_init()
    thread.create_and_start(tcp_mud_server)
	for {
		
	}
}