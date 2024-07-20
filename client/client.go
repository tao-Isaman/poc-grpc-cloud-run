package main

import (
	"context"
	"log"

	"google.golang.org/grpc"
	"poc-grpc-cloud-run/hello"
)

func main() {
	conn, err := grpc.Dial("localhost:50051", grpc.WithInsecure())
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer conn.Close()

	c := hello.NewHelloServiceClient(conn)

	// SayHello
	req := &hello.HelloRequest{Name: "World"}
	res, err := c.SayHello(context.Background(), req)
	if err != nil {
		log.Fatalf("could not greet: %v", err)
	}
	log.Printf("Greeting: %s", res.Message)
}
