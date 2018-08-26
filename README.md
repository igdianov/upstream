Basic example of upstream library repo to test updatebot

The updatebot uses custom branch name configuration in .updatebot.yml to clone and checkout remote downstream repository branch, compute and apply version changes, and then push updates to downstream repository via Pull Request back to custom branch.

Here is the sample .updatebot.yml used by updatebot:

```yaml
github:
  organisations:
  - name: igdianov
    repositories:
    - name: downstream
      # use custom branch 
      branch: develop
```

If custom branch is not configured, the updatebot will try to use default branch for Github repositories. Otherwise, it will default to master branch. 

This version of updatebot also tries to resolve local repository name from Git clone url, so that `updatebot push --ref tag` generates nice Pull Request title, i.e. `update igdianov/upstream to tag` in downstream repository.

