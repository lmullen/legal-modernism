import argparse
import os
import subprocess

# def shell(cmd_array):
#     try:
#         subprocess.check_output(cmd_array, stderr=subprocess.STDOUT)
#     except subprocess.CalledProcessError ex:

def migrate(env):
    target_env = env or "development" 
    os.system("knex migrate:latest --env={e}".format(e=target_env))

def validate_env(target_env):
    return target_env in ('beta', 'production')

# def make_commit_message(args):
#     args.action = args.action or ""
#     commit_message = "\"{0.ticket} #{0.action} {0.msg}\"".format(args)
#     return commit_message 

# def merge(commit_message, branch, cb_commit):
#     cmd = "git merge {b} -m {m}".format(b = branch, m = commit_message)
#     exit_code = os.system(cmd)

#     if exit_code != 0:
#         reset(cb_commit)
#     else:
#         push("beta-testing")
#         checkout(branch)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument('--env', action='store', help='Sets the env for which to run migrations.')

    args = parser.parse_args()
    assert validate_env(args.env), "Invalid target environment; options are 'beta', 'production'"

    migrate(args.env) 
  