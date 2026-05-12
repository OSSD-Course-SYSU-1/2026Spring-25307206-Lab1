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
import { fileIo as fs } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { GameStepBase } from './GameStepBase';
import { CommonConstants, TAG, DOMAINID } from '../common/CommonConstants';
import { AssetSessionStorage } from '../session/AssetSessionStorage';

export interface StepDownloadResult {
  nextStep: number;
  version: string;
}

export interface StepDownloadProgress {
  progress: number;
  speed: number;
  totalWritten: number;
  totalSize: number;
  expectedTime: number;
}

export class GameStepDownload extends GameStepBase {
  private nextStep: number = -1;
  private version: string;
  private downloadProgress: StepDownloadProgress;
  private downloadsInfo: Map<string, number> = new Map<string, number>();
  private totalSize: number = 0;
  private totalDownloadSize: number = 0;
  private downloadCompleteSize: number = 0;
  private speed: number = 1024 * 1024;
  private taskNumber: number = 0;
  private storage_: AssetSessionStorage|null = null;
  private notificationId: number = 0;

  constructor(context: common.Context, version: string) {
    super(context);
    hilog.info(DOMAINID, TAG, `GameStepDownload constructor version: ${version}`);
    this.version = version + '';
    this.downloadProgress = {
      progress: 0,
      speed: 0,
      totalWritten: 0,
      totalSize: 0,
      expectedTime: 0
    };
    this.startBackgroundRunning();
  }

  public Stop(): void {
    hilog.info(DOMAINID, TAG, 'GameStepDownload Stop.');
    setTimeout(async () => {
      this.DeleteAssetDownloadListener();
    }, 0)
    hilog.info(DOMAINID, TAG, 'GameStepDownload Stop end.');
  }

  public Start(): void {
    hilog.info(DOMAINID, TAG, 'GameStepDownload Start.');
    setTimeout(async () => {
      this.AddAssetDownloadListener();
      this.storage_ = await AssetSessionStorage.create(this.context_);
      try {
        let group = await this.storage_.queryGroupInfoByGroupId(this.version);
        this.totalSize = group.totalSize;
        this.downloadCompleteSize = group.downloadedSize;
      } catch (error) {
        hilog.error(DOMAINID,
          TAG, `failed to queryGroupInfoByGroupId, errCode: ${error.code}, errMessage: ${error.message}`);
      }
      this.requestAssetDownload();
    }, 0)
    hilog.info(DOMAINID, TAG, 'GameStepDownload Start end.');
  }

  protected GetProgressObject(): object {
    let currentDownloadSize = 0;
    for (const key of this.downloadsInfo.keys()) {
      let size: number = this.downloadsInfo.get(key) as number;
      currentDownloadSize = currentDownloadSize + size;
    }
    let speed = currentDownloadSize - this.totalDownloadSize;
    hilog.info(DOMAINID,
      TAG, `total size = ${this.totalSize}, currentDownloadSize = ${currentDownloadSize}, totalDownloadSize`
      + ` = ${this.totalDownloadSize}, speed = ${speed}`);
    if (speed > 0) {
      this.speed = speed;
    }
    this.totalDownloadSize = currentDownloadSize;
    let remindSize = this.totalSize - this.totalDownloadSize - this.downloadCompleteSize;
    let expectedTime = remindSize / this.speed;
    let progress = (this.totalDownloadSize + this.downloadCompleteSize) * 100 / this.totalSize;
    if (progress > 100) {
      progress = 100;
      this.nextStep = 3;
      this.stopContinuousTask();
    }
    this.updateProcess(progress);
    this.downloadProgress = {
      progress: progress,
      speed: this.speed,
      totalWritten: this.totalDownloadSize + this.downloadCompleteSize,
      totalSize: this.totalSize,
      expectedTime: expectedTime
    }
    hilog.info(DOMAINID, TAG, `downloadProgress: ${JSON.stringify(this.downloadProgress)}`);
    return this.downloadProgress;
  }

  protected CheckFinish(): boolean {
    return this.downloadProgress.progress >= 100;
  }

  async resumeAssetDownload() {
    this.version = this.version + '';
    hilog.info(DOMAINID, TAG, `resumeAssetDownload start, groupId：${this.version}`);

    hilog.info(DOMAINID, TAG, `resumeAssetDownload taskNumber ${this.taskNumber}`);
  }

  async addAssetDownload() {
    hilog.info(DOMAINID, TAG, `addAssetDownload enter.`);
    if (this.storage_ === null) {
      hilog.info(DOMAINID, TAG, `storage_ is null.`);
      return;
    }
    const limit = 200;

    hilog.info(DOMAINID, TAG, `addAssetDownload taskNumber ${this.taskNumber}`);
  }

  async requestAssetDownload() {
    await this.resumeAssetDownload();
    if (this.taskNumber === 0) {
      await this.addAssetDownload();
    }
  }

  // Subscribing to Download Status and Download Progress Events.
  private AddAssetDownloadListener() {
    try {

    } catch (error) {
      hilog.error(DOMAINID,
        TAG, `assetDownloadManager.on failed, errCode: ${error.code}, errMessage: ${error.message}`);
      return;
    }
    hilog.info(DOMAINID, TAG, `assetDownloadManager.on success.`);
  }

  // Deleting an Event Listener.
  private DeleteAssetDownloadListener() {
    try {

    } catch (error) {
      hilog.error(DOMAINID,
        TAG, `assetDownloadManager.off failed, errCode: ${error.code}, errMessage: ${error.message}`);
    }
  }

  taskNumberMinus() {
    this.taskNumber--;
    if (this.taskNumber === 0) {
      this.requestAssetDownload();
    }
  }

  taskNumberPlus() {
    this.taskNumber++;
  }

  GetResult(): object {
    let result: StepDownloadResult = {
      nextStep: this.nextStep,
      version: this.version
    }
    return result;
  }

  startBackgroundRunning() {
    hilog.info(DOMAINID, TAG, `startBackgroundRunning start`);

  }

  stopContinuousTask() {

  }

  updateProcess(process: Number) {
    hilog.info(DOMAINID, TAG, `update task progress. ${process}`);

  }
}