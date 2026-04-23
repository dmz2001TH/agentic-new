import React, { useState, useEffect, useRef } from 'react';
import { Mic, Send, Zap, Shield, HardDrive, Layout, Volume2, MicOff, AlertCircle } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import axios from 'axios';

function App() {
  const [input, setInput] = useState('');
  const [messages, setMessages] = useState([
    { role: 'ai', text: 'สวัสดีครับนายท่าน ผม JARVIS ระบบได้รับการอัปเกรดไมโครโฟนแล้วครับ' }
  ]);
  const [loading, setLoading] = useState(false);
  const [latestImage, setLatestImage] = useState(null);
  const [isListening, setIsListening] = useState(false);
  const [micStatus, setMicStatus] = useState('Ready'); // Ready, Listening, Denied, Error, NotSupported

  const recognitionRef = useRef(null);

  useEffect(() => {
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    
    if (!SpeechRecognition) {
      setMicStatus('NotSupported');
      console.error("Browser does not support Speech Recognition.");
      return;
    }

    const recognition = new SpeechRecognition();
    recognition.continuous = false;
    recognition.lang = 'th-TH';
    recognition.interimResults = false;

    recognition.onstart = () => {
      setIsListening(true);
      setMicStatus('Listening');
    };

    recognition.onresult = (event) => {
      const transcript = event.results[0][0].transcript;
      setInput(transcript);
      setIsListening(false);
      setMicStatus('Ready');
      // ส่งคำสั่งทันที
      handleSend(transcript);
    };

    recognition.onerror = (event) => {
      console.error("Speech recognition error:", event.error);
      setIsListening(false);
      if (event.error === 'not-allowed') setMicStatus('Denied');
      else setMicStatus('Error');
    };

    recognition.onend = () => {
      setIsListening(false);
      if (micStatus !== 'Denied') setMicStatus('Ready');
    };

    recognitionRef.current = recognition;
  }, []);

  const toggleListen = () => {
    if (micStatus === 'NotSupported') {
      alert("Browser ของคุณไม่รองรับการสั่งงานด้วยเสียง กรุณาใช้ Chrome หรือ Edge ครับ");
      return;
    }

    if (isListening) {
      recognitionRef.current?.stop();
    } else {
      try {
        recognitionRef.current?.start();
      } catch (e) {
        console.error("Could not start recognition", e);
      }
    }
  };

  const handleSend = async (forcedInput = null) => {
    const textToSend = forcedInput || input;
    if (!textToSend.trim()) return;
    
    const userMsg = { role: 'user', text: textToSend };
    setMessages(prev => [...prev, userMsg]);
    setInput('');
    setLoading(true);

    try {
      // ส่งไปหาสมอง GOD (ผ่าน FastAPI Bridge)
      const response = await axios.post('http://localhost:8000/api/chat', { message: textToSend });
      const aiMsg = { 
        role: 'ai', 
        text: response.data.message || 'Mission accomplished, sir.',
        image: response.data.image_url,
        audio: response.data.voice_url
      };
      setMessages(prev => [...prev, aiMsg]);
      if (response.data.image_url) setLatestImage(response.data.image_url);

      // --- ระบบเล่นเสียงอัตโนมัติ (Auto-Play) ---
      if (response.data.voice_url) {
        // ในระบบจริง voice_url อาจจะเป็น path หรือ base64
        // ถ้าเป็นไฟล์ในเครื่อง เราจะโหลดผ่าน URL ที่ Backend เตรียมไว้
        const audio = new Audio('http://localhost:8000' + response.data.voice_url);
        audio.play().catch(e => console.error("Audio play blocked by browser:", e));
      }
    } catch (error) {
      setMessages(prev => [...prev, { role: 'ai', text: 'Connection to Super Brain lost. Check Backend.' }]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="h-screen w-screen flex bg-[#050505] text-white overflow-hidden p-4 gap-4 font-sans">
      {/* Sidebar */}
      <div className="w-1/4 flex flex-col gap-4">
        <motion.div animate={isListening ? { scale: [1, 1.02, 1] } : {}} transition={{ repeat: Infinity }} className="bg-white/5 border border-white/10 rounded-3xl p-6 backdrop-blur-xl flex flex-col items-center text-center">
          <div className={`w-20 h-20 rounded-full flex items-center justify-center mb-4 transition-all duration-500 shadow-2xl ${isListening ? 'bg-red-500 shadow-red-500/50' : 'bg-cyan-500 shadow-cyan-500/50'}`}>
            <Zap size={36} className="text-white fill-white" />
          </div>
          <h1 className="text-xl font-black tracking-tighter uppercase">{isListening ? 'Listening...' : 'Jarvis Supreme'}</h1>
          <div className="flex items-center gap-2 mt-1">
            <div className={`w-2 h-2 rounded-full ${micStatus === 'Ready' ? 'bg-green-500' : 'bg-red-500 animate-pulse'}`}></div>
            <span className="text-[10px] font-bold text-gray-400 uppercase tracking-widest">Mic: {micStatus}</span>
          </div>
        </motion.div>

        <div className="flex-1 bg-white/5 border border-white/10 rounded-3xl p-6 backdrop-blur-xl space-y-6">
          <h2 className="text-[10px] font-bold text-gray-500 uppercase tracking-[0.2em]">Live Telemetry</h2>
          <StatItem icon={<HardDrive size={16} />} label="Disk" value="1% Used" color="text-green-400" />
          <StatItem icon={<Shield size={16} />} label="Security" value="Encrypted" color="text-cyan-400" />
          <StatItem icon={<Volume2 size={16} />} label="Voice" value="ElevenLabs" color="text-yellow-400" />
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col gap-4">
        <div className="flex-1 bg-white/5 border border-white/10 rounded-3xl p-4 backdrop-blur-xl flex items-center justify-center relative overflow-hidden">
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,_var(--tw-gradient-stops))] from-cyan-500/5 via-transparent to-transparent"></div>
          {latestImage ? (
            <motion.img initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} src={latestImage} className="max-h-full rounded-2xl shadow-[0_0_50px_rgba(0,0,0,0.5)] border border-white/10 z-10" />
          ) : (
            <div className="text-gray-600 text-sm font-bold uppercase tracking-widest flex flex-col items-center gap-4">
               <div className="w-12 h-12 border-2 border-dashed border-gray-700 rounded-full animate-spin"></div>
               Awaiting Visual Data
            </div>
          )}
        </div>

        {/* Chat Interface */}
        <div className="h-1/3 bg-white/5 border border-white/10 rounded-3xl backdrop-blur-xl flex flex-col overflow-hidden shadow-2xl">
          <div className="flex-1 overflow-y-auto p-6 space-y-4">
            {messages.map((m, i) => (
              <motion.div initial={{ opacity: 0, x: m.role === 'user' ? 20 : -20 }} animate={{ opacity: 1, x: 0 }} key={i} className={`flex ${m.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                <div className={`max-w-[75%] px-4 py-2 rounded-2xl text-sm ${m.role === 'user' ? 'bg-cyan-500 text-black font-bold shadow-lg shadow-cyan-500/20' : 'bg-white/10 text-gray-200 border border-white/5'}`}>
                  {m.text}
                </div>
              </motion.div>
            ))}
            {loading && <div className="text-cyan-500 text-[10px] font-black animate-pulse tracking-widest">JARVIS IS THINKING...</div>}
          </div>
          
          <div className="p-4 bg-black/40 flex gap-2 items-center">
            <button 
              onClick={toggleListen}
              className={`p-4 rounded-2xl transition-all ${isListening ? 'bg-red-500 text-white animate-pulse' : 'bg-white/5 text-cyan-400 hover:bg-cyan-500/10'}`}
            >
              {isListening ? <MicOff size={22} /> : <Mic size={22} />}
            </button>
            <input 
              value={input} onChange={e => setInput(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && handleSend()}
              placeholder={micStatus === 'Denied' ? "Permission denied. Type here..." : "Issue a command..."}
              className="flex-1 bg-white/5 border border-white/10 rounded-2xl px-6 py-4 text-sm focus:outline-none focus:border-cyan-500/50 transition-all placeholder:text-gray-600"
            />
            <button onClick={() => handleSend()} className="p-4 rounded-2xl bg-cyan-500 text-black font-black hover:bg-cyan-400 shadow-lg shadow-cyan-500/20 transition-all">
              <Send size={22} />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

function StatItem({ icon, label, value, color }) {
  return (
    <div className="flex items-center justify-between p-2 hover:bg-white/5 rounded-xl transition-colors">
      <div className="flex items-center gap-3">
        <div className="text-gray-400">{icon}</div>
        <span className="text-[10px] font-bold text-gray-500 uppercase tracking-wider">{label}</span>
      </div>
      <span className={`text-[10px] font-black ${color}`}>{value}</span>
    </div>
  );
}

export default App;
