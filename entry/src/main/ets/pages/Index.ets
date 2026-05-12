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
import { GameStartStep, TAG, DOMAINID } from '../common/CommonConstants';
import { GameStepDetect, StepDetectResult, StepDetectProgress } from '../task/GameStepDetect';
import { GameStepDownload, StepDownloadProgress } from '../task/GameStepDownload';

@Entry
@Component
struct Index {
  @State progress: number = 0;
  @State bytesWritten: string = '';
  @State totalWritten: string = '';
  @State totalFileNumer: number = 0;
  @State displayVersion: string = '1.0.0';
  @State step: GameStartStep = GameStartStep.STEP1;
  @State speed: string = '0.0';
  @State remindTime: string = '0m';
  @State uiContext: Context = this.getUIContext().getHostContext() as common.Context;
  @State remindTimeTitle: string = '';
  @State downloadTitle: string = '';
  @State downloadSpeedTitle: string = '';
  @State displayVersionTitle: string = '';

  Sleep(ms: number): Promise<void> {
    return new Promise((resolve) => {
      setTimeout(resolve, ms);
    })
  }

  formatBytes(bytes: number): string {
    bytes = bytes;
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    let unitIndex = 0;

    while (bytes >= 1024 && unitIndex < units.length - 1) {
      bytes /= 1024;
      unitIndex++;
    }
    return `${bytes.toFixed(2)} ${units[unitIndex]}`;
  }

  formatTime(seconds: number): string {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const remainingSeconds = seconds % 60;

    const hoursStr = hours > 0 ? `${hours}h ` : '';
    const minutesStr = minutes > 0 ? `${minutes}m ` : '';
    const secondsStr = `${remainingSeconds}s`;
    return `${hoursStr}${minutesStr}${secondsStr}`.trim();
  }

  async aboutToAppear(): Promise<void> {
    hilog.info(DOMAINID, TAG, 'aboutToAppear start.');
    this.step = GameStartStep.STEP1;
    try {
      this.remindTimeTitle = this.uiContext.resourceManager.getStringSync($r('app.string.Estimated_Time_Remaining').id);
      this.downloadTitle = this.uiContext.resourceManager.getStringSync($r('app.string.Downloading_resources').id);
      this.downloadSpeedTitle = this.uiContext.resourceManager.getStringSync($r('app.string.Speeding').id);
      this.displayVersionTitle = this.uiContext.resourceManager.getStringSync($r('app.string.Version_No').id);
    } catch (error) {
      hilog.error(DOMAINID, TAG, `failed to getStringSync, errCode: ${error.code}, errMessage: ${error.message}`);
    }
    await this.Sleep(500);
    // Detect task.
    let stepDetect: GameStepDetect = new GameStepDetect(this.uiContext);
    stepDetect.addProgressListener((inputProgress) => {
      let stepDetectProgress: StepDetectProgress = inputProgress as StepDetectProgress;
      hilog.info(DOMAINID, TAG, `GameStepDetect progress: ${stepDetectProgress.progress}`);
      this.progress = stepDetectProgress.progress;
    })
    stepDetect.Start();
    let result = await stepDetect.WaitProgressEnd();
    let stepDetectResult = result as StepDetectResult;
    hilog.info(DOMAINID, TAG, `stepDetectResult ${JSON.stringify(stepDetectResult)}`);
    await this.Sleep(1000);
    // Get next step.
    this.step = stepDetectResult.nextStep === 2 ?
      GameStartStep.STEP2 : stepDetectResult.nextStep === 3 ? GameStartStep.STEP3 : GameStartStep.STEP4;
    if (this.step === GameStartStep.STEP2) {
      this.displayVersion = stepDetectResult.version;
      this.progress = 0;
      // Download task.
      let stepDownload: GameStepDownload = new GameStepDownload(this.uiContext, stepDetectResult.version);
      stepDownload.addProgressListener((progress: object) => {
        let downloadProgress: StepDownloadProgress = progress as StepDownloadProgress;
        this.speed = this.formatBytes(downloadProgress.speed);
        this.remindTime = this.formatTime(Math.ceil(downloadProgress.expectedTime));
        this.bytesWritten = this.formatBytes(downloadProgress.totalWritten);
        this.totalWritten = this.formatBytes(downloadProgress.totalSize);
        this.progress = downloadProgress.progress;
      })
      stepDownload.Start();
      await stepDownload.WaitProgressEnd();
      await this.Sleep(500);
      this.step = GameStartStep.STEP3;
    }
    // Get next step.
    if (this.step === GameStartStep.STEP3) {
      this.displayVersion = stepDetectResult.version;
    }
  }

  @Builder
  GameStartStep1Style() {
    Column() {
      Row() {
        Text($r('app.string.Checking_for_updates'))
          .fontSize(10)
          .fontWeight(600)
          .fontColor(0xf2ebd7)
          .alignSelf(ItemAlign.Start)
        Blank()
          .width(40)
      }
      .position({ x: 30, y: '80.5%' })
      .padding({ left: 5, right: 15, bottom: 8 })
      .width('100%')
    }

    Column() {
      Progress({
        value: this.progress,
        total: 100,
        type: ProgressType.Linear
      })
        .width('90%')
        .padding({ bottom: 2 })
        .height(24)
        .position({ x: 30, y: '84%' })
        .backgroundColor('#F0FFFF')
        .color('#FF9912')
        .enabled(false)
    }
  }

  @Builder
  GameStartStep2Style() {
    Column() {
      Row() {
        Text($r('app.string.Not_Interrupted'))
          .fontSize(10)
          .fontWeight(600)
          .fontColor(0xf2ebd7)
          .alignSelf(ItemAlign.Start)
        Blank()
          .width(40)
      }
      .height(20)
      .position({ x: 25, y: '80.5%' })
      .padding({ left: 5, right: 15, bottom: 8 })
      .width('100%')
    }

    Column() {
      Row() {
        Text(String(this.remindTimeTitle) + String(this.remindTime))
          .fontSize(10)
          .fontWeight(600)
          .fontColor(0xf2ebd7)
          .alignSelf(ItemAlign.End)
          .textAlign(TextAlign.End)
          .width(200)
      }
      .height(20)
      .position({ x: 575, y: '80.5%' })
      .padding({ right: 15, bottom: 8 })
      .width(200)
    }

    Column() {
      Progress({
        value: this.progress,
        total: 100,
        type: ProgressType.Linear
      })
        .width('90%')
        .padding({ bottom: 2 })
        .height(24)
        .position({ x: 30, y: '84%' })
        .backgroundColor('#F0FFFF')
        .color('#FF9912')
        .enabled(false)
    }

    Column() {
      Row() {
        Text(String(this.downloadTitle) +
          ` ${this.bytesWritten} / ${this.totalWritten}; ` +
        String(this.downloadSpeedTitle) + ` ${this.speed}/s`)
          .fontSize(10)
          .fontWeight(600)
          .fontColor(0xf2ebd7)
          .alignSelf(ItemAlign.Start)
        Blank()
          .width(40)
      }
      .height(20)
      .position({ x: 25, y: '90%' })
      .padding({ left: 5, right: 15, bottom: 8 })
      .width('100%')
    }

    Column() {
      Row() {
        Text(String(this.displayVersionTitle) + String(this.displayVersion))
          .fontSize(10)
          .fontWeight(600)
          .fontColor(0xf2ebd7)
          .textAlign(TextAlign.End)
          .width(200)
      }.height(20)
      .position({ x: 575, y: '90%' })
      .padding({ right: 15, bottom: 8 })
      .width(200)
    }
  }

  @Builder
  GameStartStep3Style() {
    Column() {
      Row() {
        Text($r('app.string.Touch_Enter'))
          .fontSize(18)
          .fontWeight(600)
          .fontColor(0xf2ebd7)
          .fontStyle(FontStyle.Italic)
          .alignSelf(ItemAlign.Start)
        Blank()
          .width(40)
      }
      .position({ x: 350, y: '70%' })
      .padding({ left: 5, right: 15, bottom: 8 })
      .width('100%')
    }

    Column() {
      Row() {
        Text(String(this.displayVersionTitle) + String(this.displayVersion))
          .fontSize(10)
          .fontWeight(600)
          .fontColor(0xf2ebd7)
          .alignSelf(ItemAlign.Start)
        Blank()
          .width(10)
      }.height(20)
      .position({ x: 720, y: '90%' })
      .padding({ left: 5, right: 15, bottom: 8 })
      .width('100%')
    }
  }

  @Builder
  GameStartStepStyle() {
    if (this.step === GameStartStep.STEP1) {
      this.GameStartStep1Style()
    }
    if (this.step === GameStartStep.STEP2) {
      this.GameStartStep2Style()
    }
    if (this.step === GameStartStep.STEP3) {
      this.GameStartStep3Style()
    }
  }

  build() {
    Column({ space: 5 }) {
      this.GameStartStepStyle();
    }
    .backgroundImage($r('app.media.homepage'), ImageRepeat.NoRepeat)
    .backgroundImageSize(ImageSize.Cover)
    .width('100%')
    .height(400)
    .border({ width: 1 })
  }
}