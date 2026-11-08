#  DevSecOps AWS Infrastructure Automation

## Branch: main

Infrastructure-as-Code (IaC) repository provisioning a secure, VPC and AWS EKS cluster.
We are using public modules to apply the resources. To simplyfy the setup, don't have sub-modules.
We apply the resources via a pipeline using GitLab CI - so the variable values are defined in GitLab.

This project is built iteratively across feature branches to demonstrate my DevSecOps bootcamp learning. It was forked from the original course repo, howver my branches have the suffix `-dom`

* `feature/1-rbac-update-dom`
* `feature/2-iac-pipeline-dom`
* `feature/3-eks-blueprints-dom`
* `feature/4-argocd-gitops-dom`
* `feature/5-policy-as-code-dom`

---

## Branch: feature/1-rbac-update-dom

We are adding Kubernetes provider and additional K8s and AWS resources. e.g.

* RBAC roles and bindings
* Mapping AWS roles to K8s
* IAM roles
* The users are created manually in AWS e.g. k8s-admin

## Branch: feature/2-iac-pipeline-dom

* Adding the pipeline for IaC deployment and automation.
* We initialize terraform and build-plan and apply. There is a cleanup step that can be run manually.
* The terraform plan file is saved as an artifact, so it can be applied later.
* We are using a terraform image, however had to install aws cli on it for authentication.
* In AWS under Access Management I created an Identity Provider for GitLab OIDC, then a Web Identity role, which has the Trust relationship with the    Identity Provider, allowing GitLab to assume the role and interact with AWS resources securely. For more info see -> [14_secure_iac_pipeline_for_eks_provisioning](https://gitlab.com/dominikjaro_devsecops_bootcamp/notes_overview/-/blob/aa97d58f89f23e419c84204eb2d4e33645936bc7/chapters_notes/14_secure_iac_pipeline_for_eks_provisioning.md)

## Branch: feature/3-eks-blueprints-dom

* Adding Helm provider and add_ons for , like, aws_load_balancer_controller, metrics-server, cluster_autoscaler.

## Branch: feature/4-argocd-gitops-dom

* Adding ArgoCD for GitOps management using helm charts.
* Adding ArgoCD secret for authentication in the cluster -- if I port-forward to the argocd-server pod I can use the secret to access the UI.
* I configure `gitops_url, gitops_username, gitops_password` for ArgoCD access -- the variables come from GitLab.
* In the `argo-cd.yaml` I set the source repoURL, path and other policies.
* The app will sync automatically with the repo.
* Adding another `deploy_argocd` step in the CD pipeline for updates (I use an image with awscli and kubectl on it).
* For more info -> [16_application_release_pipeline_with_argocd](https://gitlab.com/dominikjaro_devsecops_bootcamp/notes_overview/-/blob/aa97d58f89f23e419c84204eb2d4e33645936bc7/chapters_notes/16_application_release_pipeline_with_argocd.md)

## Branch: feature/5-policy-as-code-dom

* Adding the gatekeeper helm chart for policy enforcement. (in the repo: [online-boutique-gitops](https://gitlab.com/dominikjaro_devsecops_bootcamp/online-boutique-gitops) you can find the `contrainttemplate` and the `constraint`) for enforcing policies.
* To see the CRDs, I had to add another RBAC role:
  
```yaml
rule {
    api_groups = ["apiextensions.k8s.io"]
    resources  = ["customresourcedefinitions"]
    verbs      = ["get", "list", "describe"]
  }
```
* In the file [platform-argo-app.yaml](https://gitlab.com/dominikjaro_devsecops_bootcamp/devsecops-infra-automation-eks/-/blob/feature/5-policy-as-code-dom/platform-argo-app.yaml?ref_type=heads) I define the path to the gitops repo.

## Branch: feature/6-secrets-management

* Manually created a secret in AWS Secrets Manager for the cluster.
* In Terraform we created a AWS IAM Role with permissions that will be Assumed to READ the secret.
* Created a K8s Service Account which is mapped to the IAM Role for secret access.
* Added external_secrets in EKS Blueprints addons.

## Branch: feature/7-istio-dom

* Installed the Istio service main components which gives us CRDs in the cluster - In the `istio.tf` file we added:
  * `istiod` manages service mesh components and capabilities.
  * `istio-base` give us the CRDs and clutser roles
  * `istio-ingress-gateway` component to manage inbound and outbound traffic
    * For the gateway configurations see the values file `istio-ingress-values.yaml.tftpl`
      * We configure the Service (LoadBalancer) and istio labels
        * We are creating an NLB (network load balancer), internet-facing -- means routing it from the internet, it will be accessable from outside.
        * We are adding our own security groups - so we can define different firewall rules.
        * In the `istio.tf` see the `aws_security_group_reosurce`
          * The we define the HTTP and HTTPS ingress rules for the load balancer traffic.
          * Egress rules for ipv4 and ipv6 addresses on all ports
    * In the `main.tf` we add another node_group for Istio ingress objects. This ensures the gateway has nodes to run on.
      * Configure more cluster and node security rules -- these are some Ingress rules to open some ports for the Istio resources
        * We are allowing and forwarding traffic from the AWS security group load balancer to the Istio defined port range.
        (make sure  create_security_group and create_node_security_group is set to true)
   * Allow Istio sidecar injection to our microservices automatically
     * In our `kube-resources.tf` to the online-boutique namespace we are adding the label `istio-injection = enabled` -- every pod in the namespace will get the sidecar proxy.
     * We add istio side proxy injection for the argocd pods -- see `argocd-values.yaml` for the label and the `argocd.tf` to include the values file in the helm release.

See the Gitops changes -> [here online-boutique-gitops](https://gitlab.com/dominikjaro_devsecops_bootcamp/online-boutique-gitops)
More notes -> [notes_overview](https://gitlab.com/dominikjaro_devsecops_bootcamp/notes_overview)
