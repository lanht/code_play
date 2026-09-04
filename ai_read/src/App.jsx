import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  BookOpen,
  ChevronLeft,
  ChevronRight,
  FileText,
  Menu,
  Minus,
  Moon,
  Pause,
  Play,
  Plus,
  RotateCcw,
  Settings,
  Square,
  Sun,
  Upload,
  Volume2,
} from 'lucide-react';
import * as pdfjsLib from 'pdfjs-dist';
import pdfWorkerUrl from 'pdfjs-dist/build/pdf.worker.mjs?url';

pdfjsLib.GlobalWorkerOptions.workerSrc = pdfWorkerUrl;

const zoomOptions = [0.8, 1, 1.15, 1.3, 1.5, 1.75, 2];
const defaultSettings = {
  theme: 'light',
  showThumbnails: true,
  showNotes: true,
  defaultZoom: 1.15,
  speechRate: 1,
  speechPitch: 1,
  speechVoice: '',
};

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

function getFileKey(file) {
  if (!file) return '';
  return `${file.name}:${file.size}:${file.lastModified}`;
}

function getNoteKey(fileKey, pageNumber) {
  return `ai-read-note:${fileKey}:${pageNumber}`;
}

function App() {
  const [pdfDoc, setPdfDoc] = useState(null);
  const [fileName, setFileName] = useState('');
  const [fileKey, setFileKey] = useState('');
  const [pageNumber, setPageNumber] = useState(1);
  const [pageInput, setPageInput] = useState('1');
  const [scale, setScale] = useState(defaultSettings.defaultZoom);
  const [pageText, setPageText] = useState('');
  const [note, setNote] = useState('');
  const [status, setStatus] = useState('idle');
  const [error, setError] = useState('');
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);
  const [settings, setSettings] = useState(() => {
    try {
      return { ...defaultSettings, ...JSON.parse(localStorage.getItem('ai-read-settings') || '{}') };
    } catch {
      return defaultSettings;
    }
  });
  const [voices, setVoices] = useState([]);
  const [speechState, setSpeechState] = useState('idle');
  const [speechMessage, setSpeechMessage] = useState('');

  const canvasRef = useRef(null);
  const renderTaskRef = useRef(null);
  const fileInputRef = useRef(null);

  const pageCount = pdfDoc?.numPages || 0;
  const speechSupported = typeof window !== 'undefined' && 'speechSynthesis' in window && 'SpeechSynthesisUtterance' in window;

  useEffect(() => {
    document.documentElement.dataset.theme = settings.theme;
    localStorage.setItem('ai-read-settings', JSON.stringify(settings));
  }, [settings]);

  useEffect(() => {
    if (!speechSupported) return;

    const loadVoices = () => {
      setVoices(window.speechSynthesis.getVoices());
    };

    loadVoices();
    window.speechSynthesis.addEventListener('voiceschanged', loadVoices);
    return () => window.speechSynthesis.removeEventListener('voiceschanged', loadVoices);
  }, [speechSupported]);

  useEffect(() => {
    setPageInput(String(pageNumber));
  }, [pageNumber]);

  useEffect(() => {
    if (!fileKey || !pageNumber) {
      setNote('');
      return;
    }
    setNote(localStorage.getItem(getNoteKey(fileKey, pageNumber)) || '');
  }, [fileKey, pageNumber]);

  useEffect(() => {
    if (!fileKey || !pageNumber) return;
    localStorage.setItem(getNoteKey(fileKey, pageNumber), note);
  }, [fileKey, pageNumber, note]);

  const stopSpeech = useCallback(() => {
    if (!speechSupported) return;
    window.speechSynthesis.cancel();
    setSpeechState('idle');
  }, [speechSupported]);

  useEffect(() => {
    return () => {
      if (renderTaskRef.current) renderTaskRef.current.cancel();
      if (speechSupported) window.speechSynthesis.cancel();
    };
  }, [speechSupported]);

  useEffect(() => {
    if (!pdfDoc) return;

    let cancelled = false;
    async function renderPage() {
      setStatus('rendering');
      setError('');
      setPageText('');

      if (renderTaskRef.current) {
        renderTaskRef.current.cancel();
      }

      try {
        const page = await pdfDoc.getPage(pageNumber);
        const viewport = page.getViewport({ scale });
        const canvas = canvasRef.current;
        const context = canvas.getContext('2d', { alpha: false });
        const ratio = window.devicePixelRatio || 1;

        canvas.width = Math.floor(viewport.width * ratio);
        canvas.height = Math.floor(viewport.height * ratio);
        canvas.style.width = `${Math.floor(viewport.width)}px`;
        canvas.style.height = `${Math.floor(viewport.height)}px`;
        context.setTransform(ratio, 0, 0, ratio, 0, 0);

        const renderTask = page.render({ canvasContext: context, viewport });
        renderTaskRef.current = renderTask;
        await renderTask.promise;

        const textContent = await page.getTextContent();
        const text = textContent.items.map((item) => item.str).join(' ').replace(/\s+/g, ' ').trim();

        if (!cancelled) {
          setPageText(text);
          setStatus('ready');
          setSpeechMessage(text ? '' : '当前页没有可朗读文本');
        }
      } catch (err) {
        if (err?.name === 'RenderingCancelledException') return;
        if (!cancelled) {
          setStatus('error');
          setError('这一页渲染失败，请尝试重新上传 PDF。');
        }
      }
    }

    stopSpeech();
    renderPage();

    return () => {
      cancelled = true;
      if (renderTaskRef.current) renderTaskRef.current.cancel();
    };
  }, [pdfDoc, pageNumber, scale, stopSpeech]);

  async function handleFileChange(event) {
    const file = event.target.files?.[0];
    if (!file) return;

    setStatus('loading');
    setError('');
    setPdfDoc(null);
    setPageNumber(1);
    setPageInput('1');
    setFileName(file.name);
    setFileKey(getFileKey(file));
    setScale(settings.defaultZoom);
    stopSpeech();

    try {
      const buffer = await file.arrayBuffer();
      const loadingTask = pdfjsLib.getDocument({ data: buffer });
      const doc = await loadingTask.promise;
      setPdfDoc(doc);
      setStatus('ready');
    } catch {
      setStatus('error');
      setError('PDF 加载失败，请确认文件没有损坏或加密。');
      setPdfDoc(null);
    }
  }

  function goToPage(nextPage) {
    if (!pageCount) return;
    setPageNumber(clamp(nextPage, 1, pageCount));
  }

  function commitPageInput() {
    const nextPage = Number(pageInput);
    if (!Number.isFinite(nextPage)) {
      setPageInput(String(pageNumber));
      return;
    }
    goToPage(nextPage);
  }

  function updateScale(nextScale) {
    setScale(clamp(Number(nextScale.toFixed(2)), 0.6, 2.4));
  }

  function resetReader() {
    stopSpeech();
    setPdfDoc(null);
    setFileName('');
    setFileKey('');
    setPageNumber(1);
    setPageInput('1');
    setPageText('');
    setNote('');
    setStatus('idle');
    setError('');
    if (fileInputRef.current) fileInputRef.current.value = '';
  }

  function speakCurrentPage() {
    if (!speechSupported) {
      setSpeechMessage('当前浏览器不支持语音朗读');
      return;
    }
    if (!pageText) {
      setSpeechMessage('当前页没有可朗读文本');
      return;
    }

    window.speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(pageText);
    const selectedVoice = voices.find((voice) => voice.name === settings.speechVoice);

    if (selectedVoice) utterance.voice = selectedVoice;
    utterance.lang = selectedVoice?.lang || 'zh-CN';
    utterance.rate = settings.speechRate;
    utterance.pitch = settings.speechPitch;
    utterance.onstart = () => {
      setSpeechState('speaking');
      setSpeechMessage('正在朗读当前页');
    };
    utterance.onend = () => {
      setSpeechState('idle');
      setSpeechMessage('朗读完成');
    };
    utterance.onerror = () => {
      setSpeechState('idle');
      setSpeechMessage('朗读被中断或失败');
    };

    window.speechSynthesis.speak(utterance);
  }

  function pauseSpeech() {
    if (!speechSupported) return;
    window.speechSynthesis.pause();
    setSpeechState('paused');
    setSpeechMessage('朗读已暂停');
  }

  function resumeSpeech() {
    if (!speechSupported) return;
    window.speechSynthesis.resume();
    setSpeechState('speaking');
    setSpeechMessage('继续朗读');
  }

  const selectedVoiceLabel = useMemo(() => {
    const voice = voices.find((item) => item.name === settings.speechVoice);
    return voice ? `${voice.name} · ${voice.lang}` : '浏览器默认';
  }, [settings.speechVoice, voices]);

  return (
    <main className="reader-shell">
      <header className="toolbar" aria-label="PDF 阅读工具栏">
        <div className="brand">
          <div className="brand-mark">
            <BookOpen size={21} strokeWidth={1.8} />
          </div>
          <div>
            <strong>AI Read</strong>
            <span>{fileName || '本地 PDF 阅读工作台'}</span>
          </div>
        </div>

        <div className="toolbar-actions">
          <input ref={fileInputRef} className="file-input" type="file" accept="application/pdf,.pdf" onChange={handleFileChange} />
          <button className="primary-button" type="button" onClick={() => fileInputRef.current?.click()}>
            <Upload size={17} />
            上传 PDF
          </button>

          <div className="pager" aria-label="页码导航">
            <button type="button" onClick={() => goToPage(pageNumber - 1)} disabled={!pdfDoc || pageNumber <= 1} title="上一页">
              <ChevronLeft size={18} />
            </button>
            <input
              value={pageInput}
              onChange={(event) => setPageInput(event.target.value)}
              onBlur={commitPageInput}
              onKeyDown={(event) => {
                if (event.key === 'Enter') commitPageInput();
              }}
              disabled={!pdfDoc}
              aria-label="当前页码"
            />
            <span>/ {pageCount || '-'}</span>
            <button type="button" onClick={() => goToPage(pageNumber + 1)} disabled={!pdfDoc || pageNumber >= pageCount} title="下一页">
              <ChevronRight size={18} />
            </button>
          </div>

          <div className="zoom-controls" aria-label="缩放控制">
            <button type="button" onClick={() => updateScale(scale - 0.1)} disabled={!pdfDoc} title="缩小">
              <Minus size={16} />
            </button>
            <select value={scale} onChange={(event) => updateScale(Number(event.target.value))} disabled={!pdfDoc} aria-label="缩放比例">
              {zoomOptions.map((option) => (
                <option key={option} value={option}>
                  {Math.round(option * 100)}%
                </option>
              ))}
            </select>
            <button type="button" onClick={() => updateScale(scale + 0.1)} disabled={!pdfDoc} title="放大">
              <Plus size={16} />
            </button>
          </div>

          <div className="speech-controls" aria-label="语音读书控制">
            <button type="button" onClick={speakCurrentPage} disabled={!pdfDoc || !speechSupported || speechState === 'speaking'} title="朗读当前页">
              <Volume2 size={17} />
            </button>
            <button type="button" onClick={speechState === 'paused' ? resumeSpeech : pauseSpeech} disabled={speechState === 'idle'} title={speechState === 'paused' ? '继续' : '暂停'}>
              {speechState === 'paused' ? <Play size={16} /> : <Pause size={16} />}
            </button>
            <button type="button" onClick={stopSpeech} disabled={speechState === 'idle'} title="停止">
              <Square size={15} />
            </button>
          </div>

          <button className="icon-button" type="button" onClick={() => setIsSettingsOpen((value) => !value)} title="设置">
            <Settings size={18} />
          </button>
          <button className="icon-button" type="button" onClick={resetReader} disabled={!pdfDoc} title="重置阅读器">
            <RotateCcw size={17} />
          </button>
        </div>
      </header>

      {isSettingsOpen && (
        <section className="settings-panel" aria-label="阅读设置">
          <label>
            <span>主题</span>
            <button
              className="segmented"
              type="button"
              onClick={() => setSettings((current) => ({ ...current, theme: current.theme === 'light' ? 'dark' : 'light' }))}
            >
              {settings.theme === 'light' ? <Sun size={16} /> : <Moon size={16} />}
              {settings.theme === 'light' ? '浅色' : '深色'}
            </button>
          </label>
          <label>
            <span>缩略图</span>
            <input
              type="checkbox"
              checked={settings.showThumbnails}
              onChange={(event) => setSettings((current) => ({ ...current, showThumbnails: event.target.checked }))}
            />
          </label>
          <label>
            <span>笔记页</span>
            <input type="checkbox" checked={settings.showNotes} onChange={(event) => setSettings((current) => ({ ...current, showNotes: event.target.checked }))} />
          </label>
          <label>
            <span>默认缩放</span>
            <select
              value={settings.defaultZoom}
              onChange={(event) => setSettings((current) => ({ ...current, defaultZoom: Number(event.target.value) }))}
            >
              {zoomOptions.map((option) => (
                <option key={option} value={option}>
                  {Math.round(option * 100)}%
                </option>
              ))}
            </select>
          </label>
          <label>
            <span>语速 {settings.speechRate.toFixed(1)}</span>
            <input
              type="range"
              min="0.6"
              max="1.8"
              step="0.1"
              value={settings.speechRate}
              onChange={(event) => setSettings((current) => ({ ...current, speechRate: Number(event.target.value) }))}
            />
          </label>
          <label>
            <span>音调 {settings.speechPitch.toFixed(1)}</span>
            <input
              type="range"
              min="0.7"
              max="1.4"
              step="0.1"
              value={settings.speechPitch}
              onChange={(event) => setSettings((current) => ({ ...current, speechPitch: Number(event.target.value) }))}
            />
          </label>
          <label className="voice-picker">
            <span>音色</span>
            <select value={settings.speechVoice} onChange={(event) => setSettings((current) => ({ ...current, speechVoice: event.target.value }))}>
              <option value="">{selectedVoiceLabel}</option>
              {voices.map((voice) => (
                <option key={`${voice.name}-${voice.lang}`} value={voice.name}>
                  {voice.name} · {voice.lang}
                </option>
              ))}
            </select>
          </label>
        </section>
      )}

      <section
        className={[
          'workspace',
          !settings.showThumbnails ? 'without-thumbnails' : '',
          !settings.showNotes ? 'without-notes' : '',
        ].join(' ')}
      >
        {settings.showThumbnails && (
          <aside className="thumbnail-rail" aria-label="PDF 目录缩略图">
            <div className="panel-heading">
              <Menu size={17} />
              <span>目录</span>
              <strong>{pageCount || 0}</strong>
            </div>
            <div className="thumbnail-list">
              {pdfDoc ? (
                Array.from({ length: pageCount }, (_, index) => (
                  <Thumbnail
                    key={index + 1}
                    pdfDoc={pdfDoc}
                    pageNumber={index + 1}
                    active={pageNumber === index + 1}
                    onSelect={() => goToPage(index + 1)}
                  />
                ))
              ) : (
                <div className="empty-mini">
                  <FileText size={28} />
                  <span>上传 PDF 后显示页面缩略图</span>
                </div>
              )}
            </div>
          </aside>
        )}

        <section className="reading-pane" aria-label="当前阅读页">
          {!pdfDoc && status !== 'error' && (
            <div className="drop-zone" onClick={() => fileInputRef.current?.click()} role="button" tabIndex={0}>
              <div className="drop-icon">
                <Upload size={30} />
              </div>
              <h1>选择一本 PDF 开始阅读</h1>
              <p>文件只在当前浏览器中解析。左侧生成缩略图，中间阅读，右侧记录每页笔记。</p>
              <button className="primary-button" type="button">
                <Upload size={17} />
                上传本地 PDF
              </button>
            </div>
          )}

          {error && (
            <div className="error-state">
              <FileText size={32} />
              <h2>{error}</h2>
              <button className="primary-button" type="button" onClick={() => fileInputRef.current?.click()}>
                重新选择 PDF
              </button>
            </div>
          )}

          {pdfDoc && (
            <div className="page-stage">
              <div className="page-status">
                <span>{status === 'rendering' ? '正在渲染页面...' : `第 ${pageNumber} 页`}</span>
                <span>{speechMessage || (pageText ? `${pageText.length} 字可朗读` : '文本分析中')}</span>
              </div>
              <div className="canvas-scroller">
                <canvas ref={canvasRef} className="pdf-canvas" aria-label={`PDF 第 ${pageNumber} 页`} />
              </div>
            </div>
          )}
        </section>

        {settings.showNotes && (
          <aside className="notes-pane" aria-label="笔记空白页">
            <div className="panel-heading">
              <FileText size={17} />
              <span>笔记</span>
              <strong>{pdfDoc ? `P${pageNumber}` : '-'}</strong>
            </div>
            <textarea
              value={note}
              onChange={(event) => setNote(event.target.value)}
              disabled={!pdfDoc}
              placeholder={pdfDoc ? '在这里记录这一页的重点、疑问或摘录...' : '上传 PDF 后开始记录笔记'}
            />
            <div className="note-footer">
              <span>{note.length} 字</span>
              <span>{pdfDoc ? '已自动保存到本地浏览器' : '等待 PDF'}</span>
            </div>
          </aside>
        )}
      </section>
    </main>
  );
}

function Thumbnail({ pdfDoc, pageNumber, active, onSelect }) {
  const canvasRef = useRef(null);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    let renderTask;
    let cancelled = false;

    async function renderThumbnail() {
      try {
        const page = await pdfDoc.getPage(pageNumber);
        const viewport = page.getViewport({ scale: 0.22 });
        const canvas = canvasRef.current;
        const context = canvas.getContext('2d', { alpha: false });
        const ratio = window.devicePixelRatio || 1;

        canvas.width = Math.floor(viewport.width * ratio);
        canvas.height = Math.floor(viewport.height * ratio);
        canvas.style.width = `${Math.floor(viewport.width)}px`;
        canvas.style.height = `${Math.floor(viewport.height)}px`;
        context.setTransform(ratio, 0, 0, ratio, 0, 0);
        renderTask = page.render({ canvasContext: context, viewport });
        await renderTask.promise;
      } catch (err) {
        if (!cancelled && err?.name !== 'RenderingCancelledException') setFailed(true);
      }
    }

    renderThumbnail();

    return () => {
      cancelled = true;
      if (renderTask) renderTask.cancel();
    };
  }, [pdfDoc, pageNumber]);

  return (
    <button className={`thumbnail-card ${active ? 'is-active' : ''}`} type="button" onClick={onSelect}>
      <span>{pageNumber}</span>
      {failed ? <div className="thumbnail-fallback">预览失败</div> : <canvas ref={canvasRef} />}
    </button>
  );
}

export default App;
