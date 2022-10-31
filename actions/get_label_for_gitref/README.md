<!-- start title -->

# GitHub Action: 🏷️ Get Label For GitRef

<!-- end title -->

<!-- start description -->

Get the label for a given gitref.

<!-- end description -->

## Action Usage

<!-- start usage -->

```yaml
- uses: Broadshield/actions@v1.0.1
  with:
    ref: ""

    env: ""

    # Default: dev
    release_branch: ""

    # build, patch, minor, major
    # Default: patch
    bump_release: ""

    token: ""
```

<!-- end usage -->

## GitHub Action Inputs

<!-- start inputs -->

| \***\*Input\*\***               | \***\*Description\*\***    | \***\*Default\*\*** | \***\*Required\*\*** |
| ------------------------------- | -------------------------- | ------------------- | -------------------- |
| <code>**ref**</code>            |                            |                     | **true**             |
| <code>**env**</code>            |                            |                     | **false**            |
| <code>**release_branch**</code> |                            | <code>dev</code>    | **true**             |
| <code>**bump_release**</code>   | build, patch, minor, major | <code>patch</code>  | **false**            |
| <code>**token**</code>          |                            |                     | **true**             |

<!-- end inputs -->

## GitHub Action Outputs

<!-- start outputs -->

| \***\*Output\*\***                  | \***\*Description\*\*** |
| ----------------------------------- | ----------------------- |
| <code>**on_release_branch**</code>  |                         |
| <code>**tag_name**</code>           |                         |
| <code>**tag_name_without_v**</code> |                         |
| <code>**label**</code>              |                         |
| <code>**application_prefix**</code> |                         |
| <code>**tag_ref**</code>            |                         |
| <code>**commit**</code>             |                         |

<!-- end outputs -->
