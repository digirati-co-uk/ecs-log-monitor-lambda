import json
import boto3
import os


def lambda_handler(event, context):
    print("Received event:")
    print(json.dumps(event))

    # log stream is in format <ecs-service>/<container>/<service-id>, use this to work out which svc to restart
    log_stream = event.get("logStream", "")

    if not log_stream:
        print("Could not determine log stream, aborting")
        return
    else:
        print(f"Processing log_stream {log_stream}")

    ecs_service = log_stream.split("/")[0]
    ecs_cluster = os.getenv("ECS_CLUSTER_NAME")

    print(f"Using service '{ecs_service}' in cluster '{ecs_cluster}'")

    client = boto3.client("ecs")
    response = client.describe_services(cluster=ecs_cluster, services=[ecs_service])

    services = response.get("services", [])
    if not services:
        print("No matching services found, aborting")
        return

    if should_restart(services[0]):
        print("Restarting service..")
        client.update_service(
            cluster=ecs_cluster, service=ecs_service, forceNewDeployment=True
        )


def should_restart(service):
    # Use "deployments" to determine if service needs to be restarted.
    # During normal operation this will be an array of 1 object with a status of "PRIMARY"
    # If the services has recently been restarted there will be an additional deployment object in this array
    deployments = service.get("deployments", [])
    deployment_count = len(deployments)

    if deployment_count == 0:
        print("No deployments found, restarting service")
        return True
    elif deployment_count == 1:
        print("Single deployment only, restarting service")
        return True
    else:
        print(f"{deployment_count} deployment found, already restarted. Nothing to do")
        return False
