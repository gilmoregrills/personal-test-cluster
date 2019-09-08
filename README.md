# Test Cluster Terraform Templates

Terraform templates for a super budget kubernetes cluster running on AWS and using kubeadm.

## To Deploy:

`terraform init && terraform apply` will create the infrastructure, and the user data for each node type should handle initialising the cluster/joining it. 

Currently, because it's all hacked into the user-data for the nodes, sometimes if the worker nodes come up too early they can fail to join the cluster. If this happens just terminate the workers and they'll come back up correctly. In the future this problem should be solved by refactoring the bootstrap scripts as systemd units. 

Once the cluster is initialised, the master will start [flux](https://github.com/fluxcd/flux) and flux will attempt to apply the config files contained in the repository passed to it on startup.

## TODO:

- Sort out public/private node division properly (masters and workloads run in private subnets, with public node for ingress/loadbalancing)
- Public node creates a route53 record for itself when it initialises?
- Route53 record for the apiserver?
- Can I run masters as spot instances somehow?
- Refactor user-data to systemd units either passed in user-data or baked into the AMI
- Dashboard? Monitoring? Especially interested in cost

## Notes:

- Workers can run as spot instances, nbd, assuming it's just for personal projects
- If the cluster dies for some reason, masters should be terminated first, then the workers
