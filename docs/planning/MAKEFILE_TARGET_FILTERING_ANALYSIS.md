# Makefile Target Filtering Analysis

**Source Repository:** [make-templates](https://github.com/glblackburn/make-templates) (canonical version)
**Document Location:** [docs/planning/MAKEFILE_TARGET_FILTERING_ANALYSIS.md](https://github.com/glblackburn/make-templates/blob/main/docs/planning/MAKEFILE_TARGET_FILTERING_ANALYSIS.md)
**Implementation Example:** [aws-bin](https://github.com/glblackburn/aws-bin) - [docs/planning/MAKEFILE_TARGET_FILTERING_ANALYSIS.md](https://github.com/glblackburn/aws-bin/blob/main/docs/planning/MAKEFILE_TARGET_FILTERING_ANALYSIS.md)

## Document Relationship

This document is the **canonical source of truth** for analyzing options to reduce Makefile target clutter when using make-templates. It was created during the **aws-bin** project implementation and is maintained here in the make-templates repository for the benefit of all projects using make-templates.

**Document Copies:**
- **Source/Canonical Version:** This document in [make-templates repository](https://github.com/glblackburn/make-templates)
  - Location: `docs/planning/MAKEFILE_TARGET_FILTERING_ANALYSIS.md`
  - GitHub: [https://github.com/glblackburn/make-templates/blob/main/docs/planning/MAKEFILE_TARGET_FILTERING_ANALYSIS.md](https://github.com/glblackburn/make-templates/blob/main/docs/planning/MAKEFILE_TARGET_FILTERING_ANALYSIS.md)
  - **This is the source of truth** - all general updates should be made here
- **Reference Copy:** [aws-bin repository](https://github.com/glblackburn/aws-bin)
  - Location: `docs/planning/MAKEFILE_TARGET_FILTERING_ANALYSIS.md`
  - GitHub: [https://github.com/glblackburn/aws-bin/blob/main/docs/planning/MAKEFILE_TARGET_FILTERING_ANALYSIS.md](https://github.com/glblackburn/aws-bin/blob/main/docs/planning/MAKEFILE_TARGET_FILTERING_ANALYSIS.md)
  - This is a reference copy showing the implementation in aws-bin project

**Recommendation:** Projects using make-templates should reference this canonical version in the make-templates repository. The aws-bin version serves as a reference implementation example.

**Linking Strategy:**
- **make-templates version** (this document, canonical) links to aws-bin implementation as an example
- **aws-bin version** should link to this document as the "canonical/source version"
- This creates bidirectional linking for easy navigation between the two repositories
- The make-templates version is the source of truth and should be updated for general improvements
- Project-specific implementations (like aws-bin) can maintain their own copies with project-specific details

## Implementation Status

**✅ SELECTED AND IMPLEMENTED: Option 1 - Selectively Include Modules**

**Implementation Date:** 2026-01-09
**Implementation Project:** [aws-bin](https://github.com/glblackburn/aws-bin)

**Status:** Implemented in aws-bin Makefile. The Makefile now explicitly includes only:
- `Makefile_standard.mk` (standard operations)
- `Makefile_software.mk` (tool installation)

**Excluded modules:**
- `Makefile_terraform.mk` (no terraform in aws-bin project)
- `Makefile_docker.mk` (no docker in aws-bin project)
- `Makefile_package_json.mk` (no Node.js in aws-bin project)

**Result:** Help output reduced from 47 targets to ~15-20 targets, showing only relevant operations for a bash scripts project.

**Implementation Example:** See [aws-bin Makefile](https://github.com/glblackburn/aws-bin/blob/main/Makefile) for the actual implementation.

## Current Situation

**Before implementation:** 47 targets shown (when all modules included)
**After implementation:** ~15-20 targets shown (estimated, with selective inclusion)

**Targets by module:**
- `Makefile_standard.mk`: ~7 targets (help, clean, open-github, create-pull-request, make-dirs-git-*, standard-info)
- `Makefile_software.mk`: ~20+ targets (install-*, brew, tfenv, etc.)
- `Makefile_terraform.mk`: ~12 targets (apply, plan, destroy, init, output, terraform-info, show-envs, etc.)
- `Makefile_docker.mk`: ~6 targets (docker-build, docker-push, docker-run, docker-info, etc.)
- `Makefile_package_json.mk`: ~6 targets (get-name, get-version, increment-version, commit-version, config, package-info)

**Relevant targets for bash scripts projects:**
- `help` - Show available targets
- `clean` - Clean temporary files
- `open-github` - Open GitHub repo
- `create-pull-request` - Create PR
- `make-dirs-git-status` - Status of .make dirs
- `make-dirs-git-pull` - Update .make dirs
- `standard-info` - Show git info
- `install-jq` - Install jq
- `install-aws-cli` - Install AWS CLI (when added to make-templates)
- `install-shellcheck` - Install shellcheck (when added to make-templates)
- `install-shfmt` - Install shfmt (when added to make-templates)
- `install-bats` - Install bats (when added to make-templates)

**Not relevant for bash scripts projects:**
- All Terraform targets (unless project uses terraform)
- All Docker targets (unless project uses docker)
- All package.json targets (unless project uses Node.js)
- Many software install targets (terraform, java, python libs, etc. - unless needed)

## Options to Reduce Targets

### Option 1: Selectively Include Only Specific Modules

**Approach:** Modify the Makefile to only include specific modules instead of all modules.

**Implementation:**
```makefile
# Only include specific modules
-include .make/make/Makefile_standard.mk
-include .make/make/Makefile_software.mk
# Do NOT include:
# - Makefile_terraform.mk
# - Makefile_docker.mk
# - Makefile_package_json.mk
```

**Pros:**
- Simple and explicit
- Only loads what's needed
- Reduces complexity
- Faster make execution (fewer files to parse)

**Cons:**
- Must manually maintain list of modules
- If new modules are added to make-templates, must remember to include them
- Less flexible if project needs change

**Estimated reduction:** ~18-24 targets removed (terraform, docker, package_json modules)

**Recommendation:** ⭐ **BEST OPTION** - Simple, explicit, and appropriate for most projects.

**Implementation Example:** See [aws-bin Makefile](https://github.com/glblackburn/aws-bin/blob/main/Makefile)

---

### Option 2: Override Help Target to Filter by Module

**Approach:** Create a custom `help` target that only searches specific Makefile modules.

**Implementation:**
```makefile
.PHONY: help
help: ## Show make targets (filtered for this project)
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' \
		Makefile \
		.make/make/Makefile_standard.mk \
		.make/make/Makefile_software.mk \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' | sort
```

**Pros:**
- All modules still loaded (targets still available if needed)
- Only shows relevant targets in help
- Can still use hidden targets if needed

**Cons:**
- All modules still loaded (slower, more complex)
- Targets still exist (could be confusing)
- Must maintain filter list
- Less discoverable (targets exist but not shown)

**Estimated reduction:** Help shows ~15-20 targets instead of 47

**Recommendation:** ⚠️ **ACCEPTABLE** - Works but not ideal since unused modules are still loaded.

---

### Option 3: Conditional Includes Based on File Existence

**Approach:** Only include modules if related project files exist (e.g., only include terraform if terraform.tf exists).

**Implementation:**
```makefile
# Include standard and software modules (always needed)
-include .make/make/Makefile_standard.mk
-include .make/make/Makefile_software.mk

# Conditionally include other modules
-include $(if $(wildcard terraform.tf),.make/make/Makefile_terraform.mk,)
-include $(if $(wildcard Dockerfile),.make/make/Makefile_docker.mk,)
-include $(if $(wildcard package.json),.make/make/Makefile_package_json.mk,)
```

**Pros:**
- Automatic based on project structure
- Self-documenting (only includes what's relevant)
- Flexible (changes as project evolves)

**Cons:**
- More complex Makefile
- May not always detect correctly (e.g., Dockerfile might not be in root)
- Still includes software module with all install targets

**Estimated reduction:** ~12-18 targets removed (if no terraform.tf, Dockerfile, package.json)

**Recommendation:** ⚠️ **ACCEPTABLE** - Good for multi-purpose projects.

---

### Option 4: Create Project-Specific Help with Categories

**Approach:** Create a custom help target that groups targets by category and only shows relevant categories.

**Implementation:**
```makefile
.PHONY: help
help: ## Show make targets (filtered for this project)
	@echo "=== Project Targets ==="
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "=== Standard Operations ==="
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' .make/make/Makefile_standard.mk | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "=== Tool Installation ==="
	@grep -hE '^install-(jq|aws-cli|shellcheck|shfmt|bats):.*?## .*$$' .make/make/Makefile_software.mk | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
```

**Pros:**
- Organized by category
- Only shows relevant targets
- Clear and user-friendly

**Cons:**
- More complex to maintain
- Must update when new tools are added
- All modules still loaded

**Estimated reduction:** Help shows ~12-15 relevant targets

**Recommendation:** ⚠️ **ACCEPTABLE** - Good UX but requires maintenance.

---

### Option 5: Create Project-Specific Module (Future)

**Approach:** Create a new module in make-templates specifically for certain project types (e.g., bash/AWS projects) that only includes relevant targets.

**Implementation:**
- Would require changes to make-templates repository
- New module: `Makefile_bash.mk` or similar
- Includes only standard + software (filtered) + project-specific targets

**Pros:**
- Reusable across similar projects
- Maintained in make-templates
- Clean separation of concerns

**Cons:**
- Requires make-templates changes
- Not available now
- May be overkill for single project type

**Estimated reduction:** Would show only relevant targets (~12-15)

**Recommendation:** 📋 **FUTURE OPTION** - Good for long-term but not immediate solution.

---

## Recommended Approach

### ✅ SELECTED AND IMPLEMENTED: **Option 1 - Selectively Include Modules**

**Status:** Implemented in [aws-bin project](https://github.com/glblackburn/aws-bin)

For projects that don't need all modules (e.g., bash scripts projects that don't use terraform, docker, or Node.js), the best approach is to only include the modules that are actually needed:

```makefile
# Include only relevant modules for this project
-include .make/make/Makefile_standard.mk
-include .make/make/Makefile_software.mk
# Future: -include .make/make/Makefile_bash.mk (when created)
```

**Benefits:**
- Reduces help output from 47 to ~15-20 targets
- Only loads what's needed (faster, simpler)
- Explicit and clear about project dependencies
- Easy to maintain

**Targets that will be shown:**
- Standard operations: help, clean, open-github, create-pull-request, make-dirs-git-*, standard-info
- Software installation: install-jq, install-aws-cli (when added), install-shellcheck (when added), install-shfmt (when added), install-bats (when added), plus other install targets from software module

**Targets that will be removed:**
- All Terraform targets (~12 targets) - if not needed
- All Docker targets (~6 targets) - if not needed
- All package.json targets (~6 targets) - if not needed

**Remaining software install targets:**
- Some install targets from Makefile_software.mk will still appear (install-homebrew, install-tfenv, install-terraform, install-jenv, install-openjdk, install-python, install-python-lib-*, install-redis, install-azure-cli, install-sponge, install-xmllint, install-xmlstarlet)
- These are less relevant for some projects but don't hurt to have available
- Could be further filtered if needed (Option 2 or 4)

### Secondary Recommendation: **Option 2 - Filter Help Output**

If you want to keep all modules loaded but only show relevant targets in help, use Option 2. This is useful if:
- You might need terraform/docker targets in the future
- You want maximum flexibility
- You're okay with all modules being loaded

## Implementation Notes

### If Using Option 1 (Recommended):

1. Update Makefile to explicitly list modules:
   ```makefile
   # Include only relevant modules for this project
   -include .make/make/Makefile_standard.mk
   -include .make/make/Makefile_software.mk
   # Future: -include .make/make/Makefile_bash.mk
   ```

2. Document why certain modules are excluded:
   ```makefile
   # Excluded modules (not needed for this project):
   # - Makefile_terraform.mk (no terraform in this project)
   # - Makefile_docker.mk (no docker in this project)
   # - Makefile_package_json.mk (no Node.js in this project)
   ```

3. When new project-specific modules are created, add them to the includes

**Example Implementation:** See [aws-bin Makefile](https://github.com/glblackburn/aws-bin/blob/main/Makefile)

### If Using Option 2 (Alternative):

1. Override the help target after including all modules
2. Filter help output to only show relevant Makefiles
3. Document that other targets exist but aren't shown

## Summary

**✅ IMPLEMENTED:** Option 1 - Selectively include only `Makefile_standard.mk` and `Makefile_software.mk` (example in aws-bin project).

**Result:** Help output reduced from 47 targets to ~15-20 targets, showing only relevant operations for the project type.

**Implementation details:**
- Makefile updated to explicitly include only relevant modules
- Header comments updated to document included/excluded modules
- Inline comments added explaining the selective inclusion approach
- See [aws-bin Makefile](https://github.com/glblackburn/aws-bin/blob/main/Makefile) for complete example

**Future enhancement:** When project-specific modules (e.g., `Makefile_bash.mk`) are created in make-templates, add them to the includes for project-specific targets (lint, format, test).

## Related Documentation

- **This Document (make-templates, canonical):** [docs/planning/MAKEFILE_TARGET_FILTERING_ANALYSIS.md](https://github.com/glblackburn/make-templates/blob/main/docs/planning/MAKEFILE_TARGET_FILTERING_ANALYSIS.md) - **Source of truth**
- **Implementation Example (aws-bin):** [docs/planning/MAKEFILE_TARGET_FILTERING_ANALYSIS.md](https://github.com/glblackburn/aws-bin/blob/main/docs/planning/MAKEFILE_TARGET_FILTERING_ANALYSIS.md) - Reference copy
- **aws-bin Makefile Implementation:** [Makefile](https://github.com/glblackburn/aws-bin/blob/main/Makefile)
- **make-templates Repository:** [https://github.com/glblackburn/make-templates](https://github.com/glblackburn/make-templates)
- **aws-bin Repository:** [https://github.com/glblackburn/aws-bin](https://github.com/glblackburn/aws-bin)
