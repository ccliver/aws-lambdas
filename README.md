## Example Lambda code deployed using Terraform

The Makefile uses Docker as a Terraform runner for a given project:

```bash
PROJECT=ec2-scheduled-stop-start
make init
make plan
make apply
```

To build the EC2 scheduled stop/start Lambda.
