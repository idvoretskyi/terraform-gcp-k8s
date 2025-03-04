# GKE Cluster with Preemptible Nodes

This Terraform configuration creates a Google Kubernetes Engine (GKE) cluster with preemptible nodes for cost savings.

## Prerequisites

*   Google Cloud Platform (GCP) account
*   Terraform installed
*   GCP project ID

## Usage

1.  Clone this repository.
2.  Initialize Terraform:

    ```bash
    terraform init
    ```
3.  Set the `project_id` variable in `terraform.tfvars` or pass it via the command line:

    ```bash
    terraform apply -var="project_id=YOUR_PROJECT_ID"
    ```

4.  Apply the Terraform configuration:

    ```bash
    terraform apply
    ```

5.  Once the cluster is created, you can retrieve the cluster name and endpoint from the Terraform outputs.

## Configuration

*   The cluster is created with 3 preemptible nodes.
*   The node type is `e2-medium` for cost efficiency while meeting GKE requirements.
*   The region and zone are set to `us-central1` and `us-central1-a` by default, but can be customized in `variables.tf`.

## Destroy

To destroy the cluster, run:

```bash
terraform destroy
```
## Notes
*   Preemptible nodes are significantly cheaper than regular nodes but can be terminated by GCP at any time.
*   Ensure that your workloads can tolerate interruptions when using preemptible nodes.
*   For production workloads, consider using a mix of preemptible and regular nodes.
## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
## Author
*   [Ihor Dvoretskyi](https://github.com/idvoretskyi)