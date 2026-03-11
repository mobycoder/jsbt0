package mobycode.template.jsbt0.grpc;

import io.grpc.stub.StreamObserver;
import mobycode.template.jsbt0.proto.v1.PingRequest;
import mobycode.template.jsbt0.proto.v1.PingResponse;
import mobycode.template.jsbt0.proto.v1.PingServiceGrpc;
import org.springframework.grpc.server.service.GrpcService;

/**
 * Example gRPC service generated from ping.proto.
 * Demonstrates a custom proto service alongside the auto-configured health check.
 *
 * NOTE: The standard grpc.health.v1.Health service is provided automatically by
 * Spring Boot gRPC's GrpcServerHealthAutoConfiguration, which bridges it to the
 * Spring Boot Actuator health endpoint. No manual implementation is needed.
 *
 * Replace or delete this service when you start your own project.
 *
 * Test with grpcurl:
 *   grpcurl -plaintext -d '{"message":"hello"}' localhost:9090 \
 *     mobycode.template.jsbt0.v1.PingService/Ping
 *   grpcurl -plaintext localhost:9090 grpc.health.v1.Health/Check
 */
@GrpcService
public class PingGrpcService extends PingServiceGrpc.PingServiceImplBase {

    @Override
    public void ping(PingRequest request, StreamObserver<PingResponse> responseObserver) {
        String reply = request.getMessage().isBlank() ? "pong" : request.getMessage();
        responseObserver.onNext(PingResponse.newBuilder().setMessage(reply).build());
        responseObserver.onCompleted();
    }
}
