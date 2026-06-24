import React, { useEffect } from 'react';
import { calendlyUrl, hasCalendly } from '../config/site';

const CalendlyEmbed = () => {
  useEffect(() => {
    if (!hasCalendly) return;

    const existing = document.getElementById('calendly-widget-js');
    if (existing) return;

    const link = document.createElement('link');
    link.href = 'https://assets.calendly.com/assets/external/widget.css';
    link.rel = 'stylesheet';
    document.head.appendChild(link);

    const script = document.createElement('script');
    script.id = 'calendly-widget-js';
    script.src = 'https://assets.calendly.com/assets/external/widget.js';
    script.async = true;
    document.body.appendChild(script);

    return () => {
      link.remove();
      script.remove();
    };
  }, []);

  if (!hasCalendly) return null;

  return (
    <div
      className="calendly-inline-widget rounded-xl overflow-hidden border border-cyan/20"
      data-url={calendlyUrl}
      style={{ minWidth: '320px', height: '700px' }}
    />
  );
};

export default CalendlyEmbed;
