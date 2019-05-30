#!/usr/bin/env python

################################################################################
#
#   Description:
#   ------------
#       Generic git helper functions.
#
################################################################################

import subprocess
import sys


################################################################################
#
#   A custom git exception class
#
################################################################################

class GitException(Exception):
    pass


################################################################################
#
#   Runs a git command
#
#   Returns:
#       the stdout output of the git command if the command succeeded
#
#   Throws:
#       GitException if the git command failed. The exception will have two
#       arguments - the first is the command that failed and the second is the
#       stderr output
#
################################################################################

def run_command(*args, **kwargs):
    args = list(args)
    args.insert(0, 'git')
    kwargs['stdout'] = subprocess.PIPE
    kwargs['stderr'] = subprocess.PIPE
    proc = subprocess.Popen(args, **kwargs)
    (stdout, stderr) = proc.communicate()
    if proc.returncode != 0:
        raise GitException(" ".join(args), stderr)
    return stdout.rstrip('\n')


################################################################################
#
#   Checks whether we are in a git repository
#
#   Returns:
#       The top-level directory of the git repository if we are in one, an empty
#       string otherwise
#
################################################################################

def in_repo():
    try:
        git_top = run_command('rev-parse', '--show-toplevel')
    except GitException as e:
        return ""
    return git_top


################################################################################
#
#   Gets the current branch name
#
#   Returns:
#       The name of the currently checked out branch if there is one, an empty
#       string otherwise
#
################################################################################

def get_current_branch():
    try:
        branch_name = run_command('symbolic-ref', '--short', 'HEAD')
    except GitException as e:
        return ""
    return branch_name


################################################################################
#
#   Checks whether something is a valid git commit (or an annotated tag that
#   points at a commit)
#
#   Params:
#       ref = the reference to check
#
#   Returns:
#       True if the given string is a valid git commit, false otherwise
#
################################################################################

def is_valid_commit(ref):
    ref = ref + '^{commit}'
    try:
        run_command('rev-parse', '--quiet', '--short', '--verify', ref)
    except GitException as e:
        return False
    return True


################################################################################
#
#   Checks whether something is a valid git object of any type
#
#   Params:
#       ref = the reference to check
#
#   Returns:
#       True if the given string is a valid git object, false otherwise
#
################################################################################

def is_valid_object(ref):
    ref = ref + '^{object}'
    try:
        run_command('rev-parse', '--quiet', '--short', '--verify', ref)
    except GitException as e:
        return False
    return True


################################################################################
#
#   Gets a list of the basic details of all commits in the given range. Note
#   that the start of the range is *not* included in the returned list.
#
#   Each element of the list contains the information of a single commit
#   starting from the end of the range and going towards the start. Each element
#   contains the short hash of the commit followed by a space followed by the
#   title of the commit.
#
#   Params:
#       start = start of the range (not included in the returned list)
#       end = end of the range
#
#   Returns:
#       A list containing the basic details of all commits in the range. An
#       empty list if there are no commits in the range or if an error occurred.
#
################################################################################

def get_commits_list(start, end):
    commits_range = start + '..' + end

    try:
        git_log_output = run_command('log', '--oneline', commits_range)
    except GitException as e:
        print "Git command '{}' failed with the following error:".format(e.args[0])
        print e.args[1].rstrip('\n')
        return []

    if not git_log_output:
        # There are no commits in the range
        return []

    return git_log_output.split('\n')


################################################################################
#
#   Checks whether gpg signing of commits is enabled
#
#   Returns:
#       True if gpg signing of commits is enabled, false otherwise
#
################################################################################

def is_gpg_signing_enabled():
    try:
        run_command('config', 'user.signingkey')
    except GitException as e:
        return False
    return True


################################################################################
#
#   Gets the email address of the current user
#
#   Returns:
#       The email address of the current user, an empty string if an error
#       occurred
#
################################################################################

def get_user_email():
    try:
        user_email = run_command('config', 'user.email')
    except GitException as e:
        return ""
    return user_email

# vim: set tw=80 :
