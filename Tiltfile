# Runs the agent image in a dev k8s namespace as a long-lived "shell" pod:
# tmux is kept running instead of the Jenkins JNLP agent, so you can
# `kubectl exec` / attach into the container until `tilt down`.
#
#   tilt up
#   kubectl exec -it deploy/docker-agent-jnlp-node-dev -- tmux attach -t dev
version_settings(constraint='>=0.30.8')

load('ext://kubectl_build', 'kubectl_build')
default_registry('dev.docker.nexus3.linkurious.net')

ctx = k8s_context()
if ctx.endswith('k8s-preprod'):
  allow_k8s_contexts(ctx)

if not k8s_namespace().endswith("dev"):
  fail("You are not targeting a dev namespace")
builder = "builder-" + k8s_namespace()

# Detached tmux session, then block forever so the pod runs until tilt down.
# The wait loop keeps PID 1 alive and lets the pod restart if the session dies.
# ~/.npmrc is only written in this dev pod (not baked in the image) so CI is not affected.
# ${NPM_TOKEN} is expanded by npm at use time: export it in the tmux session.
npmrc_lines = [
  '@linkurious:registry = https://nexus3.linkurious.net/repository/npm/',
  '//nexus3.linkurious.net/repository/npm/:_auth = ${NPM_TOKEN}',
  'min-release-age=7',
  'min-release-age-exclude=@linkurious/*',
  'fetch-timeout = 90000',
]
write_npmrc = "[ -f ~/.npmrc ] || printf '%s\\n' " + ' '.join(["'%s'" % l for l in npmrc_lines]) + " > ~/.npmrc"
startup = write_npmrc + '; tmux new-session -d -s dev; while tmux has-session -t dev 2>/dev/null; do sleep 5; done'

name = 'docker-agent-jnlp-node'
image = 'linkurious/docker-agent-jnlp-node'

kubectl_build(
  image,
  context='.',
  dockerfile='Dockerfile',
  build_args={'BUILD_VERSION': 'tilt'},
  builder=builder,
  push=True,
  registry_secret='nexus-docker-dev-rw-secret',
)

k8s_yaml(blob("""
apiVersion: apps/v1
kind: Deployment
metadata:
  name: %(name)s-dev
  labels:
    app: %(name)s-dev
    app.kubernetes.io/name: %(name)s-dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: %(name)s-dev
  template:
    metadata:
      labels:
        app: %(name)s-dev
        app.kubernetes.io/name: %(name)s-dev
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        seccompProfile:
          type: RuntimeDefault
      imagePullSecrets:
        - name: nexus-docker-dev-rw-secret
      containers:
        - name: %(name)s
          image: %(image)s
          # Replaces the image entrypoint, so the JNLP agent is NOT started
          command: ["/bin/bash", "-lc"]
          args: [%(startup)s]
          env:
            - name: TERM
              value: xterm-256color
          # The dev namespace quota requires requests and limits on every container
          resources:
            requests:
              cpu: 250m
              memory: 512Mi
            limits:
              cpu: "2"
              memory: 4Gi
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop: ["ALL"]
          livenessProbe:
            exec:
              command: ["tmux", "has-session", "-t", "dev"]
            initialDelaySeconds: 10
            periodSeconds: 30
          readinessProbe:
            exec:
              command: ["tmux", "has-session", "-t", "dev"]
            periodSeconds: 10
          stdin: true
          tty: true
""" % {'name': name, 'image': image, 'startup': encode_json(startup)}))

k8s_resource(
  workload=name + '-dev',
)
