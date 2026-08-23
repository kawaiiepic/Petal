// Copyright © 2024 Aron Onak. All rights reserved.
// Licensed under the MIT license.
// If you have any feedback, please contact me at arononak@gmail.com
library git_stamp;

import 'package:flutter/services.dart';
//import 'package:encrypt/encrypt.dart' as crypto;

import 'package:flutter/material.dart';

import 'package:git_stamp/git_stamp.dart';

import 'data/commit_list.dart';
import 'data/diff_list.dart';
import 'data/diff_stat_list.dart';
import 'data/build_branch.dart';
import 'data/build_date_time.dart';
import 'data/build_system_info.dart';
import 'data/build_machine.dart';
import 'data/repo_creation_date.dart';
import 'data/repo_path.dart';
import 'data/observed_files_list.dart';
import 'data/app_version.dart';
import 'data/app_build.dart';
import 'data/app_name.dart';
import 'data/git_config_global_user_name.dart';
import 'data/git_config_global_user_email.dart';
import 'data/git_config_user_name.dart';
import 'data/git_config_user_email.dart';
import 'data/git_remote.dart';
import 'data/git_config_list.dart';
import 'data/git_count_objects.dart';
import 'data/git_tag_list.dart';
import 'data/git_branch_list.dart';
import 'data/git_reflog.dart';
import 'data/packages.dart';
import 'data/deps.dart';

//import 'git_stamp_encrypt_debug_key.dart';

import 'data/tool_build_type.dart';
import 'data/tool_version.dart';

final GitStamp = GitStampNodeImpl();

class GitStampNodeImpl extends GitStampNode {
  @override String get toolVersion => gitStampToolVersion;
  @override BuildType get toolBuildType => BuildType.fromString(gitStampToolBuildType);
  
  @override bool get isEncrypted => false;
  @override bool decrypt(Uint8List key, Uint8List iv) => true;

  @override String get commitListString => gitStampCommitList;
  @override String get diffListString => gitStampDiffList;
  @override String get diffStatListString => gitStampDiffStatList;
  @override String get buildMachineString => gitStampBuildMachine;
  @override String get buildBranch => gitStampBuildBranch;
  @override String get buildDateTime => gitStampBuildDateTime;
  @override String get buildSystemInfo => gitStampBuildSystemInfo;
  @override String get repoCreationDate => gitStampRepoCreationDate;
  @override String get repoPath => gitStampRepoPath;
  @override String get observedFiles => gitStampObservedFilesList;
  @override String get tagListString => gitStampGitTagList;
  @override String get branchListString => gitStampGitBranchList;
  @override String get appVersion => gitStampAppVersion;
  @override String get appBuild => gitStampAppBuild;
  @override String get appName => gitStampAppName;
  @override String get gitConfigGlobalUserName => gitStampGitConfigGlobalUserName;
  @override String get gitConfigGlobalUserEmail => gitStampGitConfigGlobalUserEmail;
  @override String get gitConfigUserName => gitStampGitConfigUserName;
  @override String get gitConfigUserEmail => gitStampGitConfigUserEmail;
  @override String get gitRemote => gitStampGitRemoteList;
  @override String get gitConfigList => gitStampGitConfigList;
  @override String get gitCountObjects => gitStampGitCountObjects;
  @override String get gitReflog => gitStampGitReflog;
  @override String get packageListString => gitStampPackages;
  @override String get deps => gitStampDeps;

  @override Widget icon() {
    return GitStampIcon(gitStamp: this);
  }
  
  @override Widget listTile({required BuildContext context, String? monospaceFontFamily}) {
    return GitStampListTile(
      gitStamp: this,
      gitStampVersion: toolVersion,
      onPressed: () {
        showMainPage(
          context: context,
          monospaceFontFamily: monospaceFontFamily,
        );
      },
    );
  }
  
  @override Widget mainPage({String? monospaceFontFamily, bool showDetails = false, bool showFiles = false}) {
    return GitStampPage(
      gitStamp: this,
      gitStampVersion: toolVersion,
      monospaceFontFamily: monospaceFontFamily,
      showDetails: showDetails,
      showFiles: showFiles,
  //    encryptDebugKey: GitStampEncryptDebugKey.key,
  //    encryptDebugIv: GitStampEncryptDebugKey.iv,
    );
  }
  
  @override Widget detailsPage({required Commit commit, String? monospaceFontFamily}) {
    return GitStampDetailsPage(
      gitStamp: this,
      commit: commit,
      monospaceFontFamily: monospaceFontFamily,
    );
  }
  
  @override void showMainPage({required BuildContext context, String? monospaceFontFamily, bool useRootNavigator = false}) {
    Navigator.of(context, rootNavigator: useRootNavigator).push(MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return mainPage(monospaceFontFamily: monospaceFontFamily);
      },
    ));
  }
  
  @override void showDetailsPage({required BuildContext context, required Commit commit, String? monospaceFontFamily, bool useRootNavigator = false}) {
    Navigator.of(context, rootNavigator: useRootNavigator).push(MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return detailsPage(commit: commit, monospaceFontFamily: monospaceFontFamily);
      },
    ));
  }
  
  @override void showLicensePage({required BuildContext context, Widget? applicationIcon, String? applicationLegalese, bool useRootNavigator = false}) {
    showGitStampLicensePage(
      context: context,
      gitStamp: this,
      applicationIcon: applicationIcon,
      applicationLegalese: applicationLegalese,
      useRootNavigator: useRootNavigator,
    );
  }
}
