const state = {
  photoFile: null,
  danceFile: null,
  photoUrl: "",
  danceUrl: "",
  isGenerating: false,
  animationId: 0,
};

const elements = {
  form: document.querySelector("#generateForm"),
  resetButton: document.querySelector("#resetButton"),
  photoInput: document.querySelector("#photoInput"),
  danceInput: document.querySelector("#danceInput"),
  photoDropzone: document.querySelector("#photoDropzone"),
  danceDropzone: document.querySelector("#danceDropzone"),
  photoPreview: document.querySelector("#photoPreview"),
  dancePreview: document.querySelector("#dancePreview"),
  stagePhoto: document.querySelector("#stagePhoto"),
  stageVideo: document.querySelector("#stageVideo"),
  emptyState: document.querySelector("#emptyState"),
  composition: document.querySelector("#composition"),
  progressLabel: document.querySelector("#progressLabel"),
  progressPercent: document.querySelector("#progressPercent"),
  progressBar: document.querySelector("#progressBar"),
  outputBadge: document.querySelector("#outputBadge"),
  resultCanvas: document.querySelector("#resultCanvas"),
  resultVideo: document.querySelector("#resultVideo"),
  generateButton: document.querySelector("#generateButton"),
  photoMeta: document.querySelector("#photoMeta"),
  videoMeta: document.querySelector("#videoMeta"),
  jobMeta: document.querySelector("#jobMeta"),
  timeline: document.querySelectorAll("#timeline li"),
  motionRange: document.querySelector("#motionRange"),
  motionValue: document.querySelector("#motionValue"),
};

const ctx = elements.resultCanvas.getContext("2d");

elements.photoInput.addEventListener("change", () => handleFile("photo"));
elements.danceInput.addEventListener("change", () => handleFile("dance"));
elements.resetButton.addEventListener("click", resetStudio);
elements.motionRange.addEventListener("input", () => {
  elements.motionValue.textContent = elements.motionRange.value;
});

elements.form.addEventListener("submit", async (event) => {
  event.preventDefault();
  if (!state.photoFile || !state.danceFile || state.isGenerating) return;

  state.isGenerating = true;
  elements.generateButton.disabled = true;
  elements.generateButton.textContent = "生成中...";
  elements.outputBadge.textContent = "提交 Runway";
  try {
    await generateDanceVideo();
    elements.generateButton.textContent = "重新生成";
  } catch (error) {
    showError(error);
    elements.generateButton.textContent = "重试生成";
  } finally {
    elements.generateButton.disabled = false;
    state.isGenerating = false;
  }
});

const apiBase = window.location.protocol === "file:" ? "http://localhost:5173" : "";

function handleFile(type) {
  const input = type === "photo" ? elements.photoInput : elements.danceInput;
  const file = input.files?.[0];
  if (!file) return;

  const url = URL.createObjectURL(file);

  if (type === "photo") {
    revokeUrl(state.photoUrl);
    state.photoFile = file;
    state.photoUrl = url;
    elements.photoPreview.src = url;
    elements.stagePhoto.src = url;
    elements.photoDropzone.classList.add("has-media");
    elements.photoMeta.textContent = `${file.name} · ${formatBytes(file.size)}`;
  } else {
    revokeUrl(state.danceUrl);
    state.danceFile = file;
    state.danceUrl = url;
    elements.dancePreview.src = url;
    elements.stageVideo.src = url;
    elements.danceDropzone.classList.add("has-media");
    elements.videoMeta.textContent = `${file.name} · ${formatBytes(file.size)}`;
    playVideo(elements.dancePreview);
    playVideo(elements.stageVideo);
  }

  revealStage();
  updateTimeline();
  drawOutputFrame(0);
}

function revealStage() {
  if (!state.photoFile && !state.danceFile) return;
  elements.emptyState.hidden = true;
  elements.composition.hidden = false;
}

function updateTimeline(activeIndex = 0) {
  const uploadedPhoto = Boolean(state.photoFile);
  const uploadedDance = Boolean(state.danceFile);

  elements.timeline.forEach((item, index) => {
    item.classList.remove("active", "done");
    if ((index === 0 && uploadedPhoto) || (index === 1 && uploadedDance)) {
      item.classList.add("done");
    }
  });

  const index = uploadedPhoto && uploadedDance ? activeIndex : uploadedPhoto ? 1 : 0;
  elements.timeline[index]?.classList.add("active");
}

async function generateDanceVideo() {
  clearResultVideo();
  updateProgress("上传素材到 Runway", 8);
  updateTimeline(2);
  animateResult(8);

  const payload = new FormData(elements.form);
  const created = await postForm("/api/generate", payload);
  elements.jobMeta.textContent = created.id;
  elements.outputBadge.textContent = "Runway 生成中";

  const task = await pollJob(created.id);
  const videoUrl = task.output?.find((url) => /\.(mp4|mov|webm)(\?|$)/i.test(url)) || task.output?.[0];
  if (!videoUrl) {
    throw new Error("Runway 任务完成了，但没有返回视频 URL。");
  }

  renderGeneratedVideo(videoUrl);
  updateProgress("生成完成", 100);
  elements.timeline.forEach((item) => item.classList.add("done"));
  elements.timeline[4].classList.add("active");
  elements.outputBadge.textContent = "Runway 结果";
}

async function postForm(path, payload) {
  const response = await fetch(`${apiBase}${path}`, {
    method: "POST",
    body: payload,
  });
  return parseJsonResponse(response);
}

async function pollJob(id) {
  const started = Date.now();
  while (Date.now() - started < 12 * 60 * 1000) {
    await wait(5000);
    const task = await parseJsonResponse(await fetch(`${apiBase}/api/jobs/${id}`));
    const progress = Math.round((task.progress ?? estimateProgress(task.status)) * 100);

    if (task.status === "PENDING" || task.status === "THROTTLED") {
      updateProgress(task.status === "THROTTLED" ? "等待 Runway 队列" : "Runway 排队中", Math.max(12, progress));
      updateTimeline(2);
    } else if (task.status === "RUNNING") {
      updateProgress("Runway 正在生成", Math.max(18, Math.min(progress, 96)));
      updateTimeline(3);
      animateResult(Math.max(18, Math.min(progress, 96)));
    } else if (task.status === "SUCCEEDED") {
      updateTimeline(4);
      return task;
    } else if (task.status === "FAILED") {
      throw new Error(task.failure || "Runway 生成失败。");
    } else if (task.status === "CANCELLED") {
      throw new Error("Runway 任务已取消。");
    }
  }
  throw new Error("等待 Runway 结果超时，请稍后在任务详情中重新查询。");
}

async function parseJsonResponse(response) {
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(data.error || data.message || `请求失败：${response.status}`);
  }
  return data;
}

function estimateProgress(status) {
  if (status === "PENDING") return 0.12;
  if (status === "THROTTLED") return 0.1;
  if (status === "RUNNING") return 0.45;
  return 0;
}

function renderGeneratedVideo(videoUrl) {
  elements.resultVideo.src = videoUrl;
  elements.resultVideo.hidden = false;
  elements.resultVideo.play().catch(() => {});
  elements.resultCanvas.hidden = true;
  document.querySelector("#outputFrame").classList.add("has-result");
}

function clearResultVideo() {
  elements.resultVideo.pause();
  elements.resultVideo.removeAttribute("src");
  elements.resultVideo.hidden = true;
  elements.resultCanvas.hidden = false;
  document.querySelector("#outputFrame").classList.remove("has-result");
}

function showError(error) {
  updateProgress("生成失败", 0);
  elements.outputBadge.textContent = "需要处理";
  elements.jobMeta.textContent = "失败";
  alert(error.message || "生成失败，请检查服务端日志。");
}

function animateResult(percent) {
  cancelAnimationFrame(state.animationId);
  const started = performance.now();
  const duration = 900;

  function frame(now) {
    const progress = Math.min((now - started) / duration, 1);
    drawOutputFrame(percent, progress);
    if (progress < 1 && state.isGenerating) {
      state.animationId = requestAnimationFrame(frame);
    }
  }

  state.animationId = requestAnimationFrame(frame);
}

function drawOutputFrame(percent = 0, pulse = 0) {
  const canvas = elements.resultCanvas;
  const width = canvas.width;
  const height = canvas.height;
  ctx.clearRect(0, 0, width, height);

  const gradient = ctx.createLinearGradient(0, 0, width, height);
  gradient.addColorStop(0, "#211b15");
  gradient.addColorStop(0.48, "#763126");
  gradient.addColorStop(1, "#0f624f");
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, width, height);

  if (elements.stagePhoto.complete && state.photoUrl) {
    drawCoverImage(elements.stagePhoto, 0, 0, width, height);
    ctx.fillStyle = "rgba(23, 19, 15, 0.34)";
    ctx.fillRect(0, 0, width, height);
  }

  const t = performance.now() / 360;
  const centerX = width / 2 + Math.sin(t) * 24 * (percent / 100);
  const centerY = height * 0.52;
  const strength = Number(elements.motionRange.value) / 100;

  drawPose(centerX, centerY, 1 + pulse * 0.08, strength, t);

  ctx.fillStyle = "rgba(255, 250, 240, 0.88)";
  ctx.font = "700 28px ui-monospace, SFMono-Regular, Menlo, Consolas, monospace";
  ctx.fillText(`${Math.round(percent)}%`, 34, height - 38);

  ctx.fillStyle = "rgba(255, 250, 240, 0.72)";
  ctx.font = "22px Georgia, Times New Roman, serif";
  ctx.fillText("Dance transfer preview", 34, height - 76);
}

function drawPose(x, y, scale, strength, t) {
  ctx.save();
  ctx.translate(x, y);
  ctx.scale(scale, scale);
  ctx.lineCap = "round";
  ctx.lineJoin = "round";
  ctx.strokeStyle = "#fffaf0";
  ctx.lineWidth = 16;
  ctx.shadowColor = "rgba(0, 0, 0, 0.38)";
  ctx.shadowBlur = 18;

  const sway = Math.sin(t) * 46 * strength;
  const kick = Math.cos(t * 1.4) * 58 * strength;

  line(0, -150, 0, 10);
  line(0, -88, -88 - sway, -22 + kick * 0.15);
  line(0, -88, 88 + sway, -26 - kick * 0.15);
  line(0, 10, -68 - sway * 0.45, 156 + kick);
  line(0, 10, 72 + sway * 0.45, 160 - kick);

  ctx.fillStyle = "#fffaf0";
  ctx.beginPath();
  ctx.arc(0, -198, 42, 0, Math.PI * 2);
  ctx.fill();

  ctx.fillStyle = "#d99b30";
  ctx.beginPath();
  ctx.arc(14, -206, 7, 0, Math.PI * 2);
  ctx.fill();

  ctx.restore();
}

function line(x1, y1, x2, y2) {
  ctx.beginPath();
  ctx.moveTo(x1, y1);
  ctx.lineTo(x2, y2);
  ctx.stroke();
}

function drawCoverImage(image, x, y, width, height) {
  const ratio = Math.max(width / image.naturalWidth, height / image.naturalHeight);
  const drawWidth = image.naturalWidth * ratio;
  const drawHeight = image.naturalHeight * ratio;
  ctx.drawImage(image, x + (width - drawWidth) / 2, y + (height - drawHeight) / 2, drawWidth, drawHeight);
}

function updateProgress(label, percent) {
  elements.progressLabel.textContent = label;
  elements.progressPercent.textContent = `${percent}%`;
  elements.progressBar.style.width = `${percent}%`;
}

function resetStudio() {
  cancelAnimationFrame(state.animationId);
  revokeUrl(state.photoUrl);
  revokeUrl(state.danceUrl);
  state.photoFile = null;
  state.danceFile = null;
  state.photoUrl = "";
  state.danceUrl = "";
  state.isGenerating = false;

  elements.form.reset();
  elements.motionValue.textContent = elements.motionRange.value;
  elements.photoPreview.removeAttribute("src");
  elements.dancePreview.removeAttribute("src");
  elements.stagePhoto.removeAttribute("src");
  elements.stageVideo.removeAttribute("src");
  elements.photoDropzone.classList.remove("has-media");
  elements.danceDropzone.classList.remove("has-media");
  elements.emptyState.hidden = false;
  elements.composition.hidden = true;
  elements.photoMeta.textContent = "未上传";
  elements.videoMeta.textContent = "未上传";
  elements.outputBadge.textContent = "准备生成";
  elements.jobMeta.textContent = "未创建";
  elements.generateButton.disabled = false;
  elements.generateButton.textContent = "生成跳舞视频";
  clearResultVideo();
  updateProgress("未开始", 0);
  updateTimeline(0);
  ctx.clearRect(0, 0, elements.resultCanvas.width, elements.resultCanvas.height);
}

function playVideo(video) {
  video.play().catch(() => {
    video.controls = true;
  });
}

function revokeUrl(url) {
  if (url) URL.revokeObjectURL(url);
}

function wait(ms) {
  return new Promise((resolve) => window.setTimeout(resolve, ms));
}

function formatBytes(bytes) {
  const units = ["B", "KB", "MB", "GB"];
  let size = bytes;
  let unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit += 1;
  }
  return `${size.toFixed(size > 10 || unit === 0 ? 0 : 1)} ${units[unit]}`;
}

drawOutputFrame(0);
