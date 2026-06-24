import React, { useEffect, useRef, useState } from 'react';
import { suggestedQuestions } from '../data/assistantKnowledge';
import { askAssistant } from '../services/assistant';
import { hasAiChat } from '../config/site';

const welcomeMessage = {
  role: 'assistant',
  content:
    'Hi — I\'m Olatunbosun\'s portfolio assistant. Ask about his experience, platform project, skills, or how to get in touch.',
};

const ASSISTANT_AVATAR = '/assistant-avatar.png';

const AssistantAvatar = ({ size = 'md', showBadge = true, className = '' }) => {
  const sizes = {
    sm: 'w-7 h-7',
    md: 'w-11 h-11',
    lg: 'w-14 h-14',
  };

  const badgeSizes = {
    sm: 'w-3.5 h-3.5 -bottom-0.5 -right-0.5',
    md: 'w-5 h-5 -bottom-0.5 -right-0.5',
    lg: 'w-6 h-6 bottom-0 right-0',
  };

  return (
    <div className={`relative flex-shrink-0 ${className}`}>
      <div
        className={`${sizes[size]} rounded-full p-[2px] bg-gradient-to-br from-cyan to-purple shadow-md shadow-cyan/20`}
      >
        <img
          src={ASSISTANT_AVATAR}
          alt="Portfolio assistant"
          className="w-full h-full rounded-full object-cover object-top border-2 border-navy"
        />
      </div>
      {showBadge && (
        <span
          className={`absolute ${badgeSizes[size]} flex items-center justify-center rounded-full bg-gradient-to-br from-cyan to-purple border-2 border-navy text-white`}
          aria-hidden="true"
        >
          <svg className={size === 'sm' ? 'w-2 h-2' : 'w-2.5 h-2.5'} fill="currentColor" viewBox="0 0 24 24">
            <path d="M9.813 15.904 9 18.75l-.813-2.846a4.5 4.5 0 0 0-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 0 0 3.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 0 0 3.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 0 0-3.09 3.09ZM18.259 8.715 18 9.75l-.259-1.035a3.375 3.375 0 0 0-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 0 0 2.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 0 0 2.455 2.456L21.75 6l-1.036.259a3.375 3.375 0 0 0-2.455 2.456ZM16.894 20.567 16.5 21.75l-.394-1.183a2.25 2.25 0 0 0-1.423-1.423L13.5 18.75l1.183-.394a2.25 2.25 0 0 0 1.423-1.423l.394-1.183.394 1.183a2.25 2.25 0 0 0 1.423 1.423l1.183.394-1.183.394a2.25 2.25 0 0 0-1.423 1.423Z" />
          </svg>
        </span>
      )}
    </div>
  );
};

const PortfolioAssistant = () => {
  const [open, setOpen] = useState(false);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [messages, setMessages] = useState([welcomeMessage]);
  const messagesEndRef = useRef(null);
  const inputRef = useRef(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, loading]);

  useEffect(() => {
    if (open) inputRef.current?.focus();
  }, [open]);

  const sendMessage = async (text) => {
    const trimmed = text.trim();
    if (!trimmed || loading) return;

    const userMessage = { role: 'user', content: trimmed };
    const history = [...messages, userMessage];
    setMessages(history);
    setInput('');
    setLoading(true);

    try {
      const reply = await askAssistant(trimmed, history);
      setMessages((prev) => [...prev, { role: 'assistant', content: reply }]);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = (event) => {
    event.preventDefault();
    sendMessage(input);
  };

  return (
    <>
      {open && (
        <div
          className="fixed inset-0 bg-navy/40 backdrop-blur-sm z-40 md:hidden"
          onClick={() => setOpen(false)}
          aria-hidden="true"
        />
      )}

      <div className="fixed bottom-5 right-5 z-50 flex flex-col items-end gap-3">
        {open && (
          <div className="w-[calc(100vw-2.5rem)] sm:w-[380px] max-h-[min(560px,calc(100vh-6rem))] flex flex-col card border-cyan/30 shadow-2xl shadow-cyan/10 p-0 overflow-hidden">
            <div className="px-4 py-4 border-b border-cyan/20 bg-gradient-to-r from-navy/90 via-navy/80 to-purple/10">
              <div className="flex items-start gap-3">
                <AssistantAvatar size="md" />
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <p className="text-sm font-bold text-white leading-tight">Olatunbosun&apos;s Assistant</p>
                      <p className="text-xs text-cyan font-medium mt-0.5">Portfolio Assistant</p>
                    </div>
                    <button
                      type="button"
                      onClick={() => setOpen(false)}
                      className="text-gray-400 hover:text-cyan transition-colors p-1 -mt-1 -mr-1 flex-shrink-0"
                      aria-label="Close assistant"
                    >
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  </div>
                  <div className="flex items-center gap-2 mt-2">
                    <span className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
                    <span className="text-xs text-gray-400">
                      {hasAiChat ? 'AI-powered · online' : 'Online · answers from profile'}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <div className="flex-1 overflow-y-auto px-4 py-4 space-y-4 min-h-[240px] max-h-[340px]">
              {messages.map((msg, index) => (
                <div
                  key={`${msg.role}-${index}`}
                  className={`flex gap-2 ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}
                >
                  {msg.role === 'assistant' && <AssistantAvatar size="sm" showBadge={false} className="mt-1" />}
                  <div
                    className={`max-w-[80%] rounded-2xl px-3 py-2 text-sm leading-relaxed ${
                      msg.role === 'user'
                        ? 'bg-gradient-to-r from-cyan to-purple text-white'
                        : 'bg-navy/80 border border-cyan/15 text-gray-200'
                    }`}
                  >
                    {msg.content}
                  </div>
                </div>
              ))}

              {loading && (
                <div className="flex gap-2 justify-start">
                  <AssistantAvatar size="sm" showBadge={false} className="mt-1" />
                  <div className="bg-navy/80 border border-cyan/15 rounded-2xl px-3 py-2 text-sm text-gray-400">
                    <span className="inline-flex gap-1">
                      <span className="animate-pulse">●</span>
                      <span className="animate-pulse" style={{ animationDelay: '150ms' }}>●</span>
                      <span className="animate-pulse" style={{ animationDelay: '300ms' }}>●</span>
                    </span>
                  </div>
                </div>
              )}
              <div ref={messagesEndRef} />
            </div>

            <div className="px-4 pb-3 flex flex-wrap gap-2">
              {suggestedQuestions.map((question) => (
                <button
                  key={question}
                  type="button"
                  onClick={() => sendMessage(question)}
                  disabled={loading}
                  className="text-xs badge hover:border-cyan/60 transition-colors disabled:opacity-50"
                >
                  {question}
                </button>
              ))}
            </div>

            <form onSubmit={handleSubmit} className="px-4 pb-4 flex gap-2 border-t border-cyan/10 pt-3">
              <input
                ref={inputRef}
                type="text"
                value={input}
                onChange={(event) => setInput(event.target.value)}
                placeholder="Ask about experience, skills, projects…"
                disabled={loading}
                className="flex-1 bg-navy/80 border border-cyan/20 rounded-lg px-3 py-2 text-sm text-white placeholder-gray-500 focus:outline-none focus:border-cyan/50"
              />
              <button
                type="submit"
                disabled={loading || !input.trim()}
                className="btn-primary py-2 px-4 text-sm disabled:opacity-50 disabled:hover:scale-100"
              >
                Send
              </button>
            </form>
          </div>
        )}

        <button
          type="button"
          onClick={() => setOpen((prev) => !prev)}
          className="relative rounded-full shadow-lg shadow-cyan/25 animate-glow focus:outline-none focus:ring-2 focus:ring-cyan/50"
          aria-label={open ? 'Close portfolio assistant' : 'Open portfolio assistant'}
          aria-expanded={open}
        >
          {open ? (
            <span className="btn-primary rounded-full w-14 h-14 flex items-center justify-center">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
              </svg>
            </span>
          ) : (
            <AssistantAvatar size="lg" />
          )}
        </button>
      </div>
    </>
  );
};

export default PortfolioAssistant;
