/*
* Copyright (c) 2025 Huawei Device Co., Ltd.
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import AssetManifest from '../common/AssetAccelManifest';
import { GameStepBase } from './GameStepBase';
import { TAG, DOMAINID } from '../common/CommonConstants';
import { AssetSessionStorage, GroupInfo } from '../session/AssetSessionStorage';

export interface StepDetectResult {
  nextStep: number;
  version: string;
}

export interface StepDetectProgress {
  progress: number;
}

export class GameStepDetect extends GameStepBase{
    private nextStep: number = -1;
    private remoteVersion : string = '';
    private stepDetectProgress : StepDetectProgress = {
      progress: 0
    }

    constructor(context: common.Context) {
      super(context);
    }

    GetResult(): object {
      let result :StepDetectResult = {
        nextStep: this.nextStep,
        version: this.remoteVersion,
      }
      return result;
    }

    protected GetProgressObject(): object {
      return this.stepDetectProgress;
    }

    protected CheckFinish(): boolean {
      return this.stepDetectProgress.progress >= 100;
    }

    public Start() {
      setTimeout(async ()=>{
        hilog.info(DOMAINID, TAG, 'GameStepDetect Start()');
        // Get remote manifestUrl.
        let manifestUrl : string = '';

        this.stepDetectProgress.progress = 30;
        this.triggerProgressCallback();
        // Get remote resources info.
        let remoteManifestInfo: AssetManifest.AssetAccelPackageVersion =
          await AssetManifest.requestRemoteManifest(manifestUrl);
        this.stepDetectProgress.progress = 60;
        this.triggerProgressCallback();
        // Get local info.
        let storage : AssetSessionStorage = await AssetSessionStorage.create(this.context_);
        let localGroupInfo : GroupInfo|null = null;
        try {
          localGroupInfo = await storage.queryGroupInfoForLatest();
        } catch (error) {
          hilog.error(DOMAINID,
            TAG, `failed to queryGroupInfoForLatest, errCode: ${error.code}, errMessage: ${error.message}`);
          this.nextStep = 2;
          this.stepDetectProgress.progress = 100;
          return;
        }
        if (remoteManifestInfo.versionNo != localGroupInfo.groupId) {
          this.remoteVersion = remoteManifestInfo.versionNo;
          hilog.info(DOMAINID, TAG, `remote has new version, version = ${remoteManifestInfo.versionNo}`);
          storage.insertDownloadResourceInfoByGroupID(remoteManifestInfo.versionFiles.versionFile,
            remoteManifestInfo.versionNo);
          this.nextStep = 2;
          this.stepDetectProgress.progress = 100;
          return;
        }
        if (localGroupInfo.totalSize != localGroupInfo.downloadedSize) {
          this.remoteVersion = remoteManifestInfo.versionNo;
          hilog.info(DOMAINID, TAG, 'local version task not finished');
          this.nextStep = 2;
          this.stepDetectProgress.progress = 100;
          return;
        }
        this.remoteVersion = remoteManifestInfo.versionNo;
        this.nextStep = 3;
        this.stepDetectProgress.progress = 100;
      }, 0)
    }
}

