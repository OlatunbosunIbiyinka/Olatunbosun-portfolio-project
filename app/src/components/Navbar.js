import React, { useState, useEffect } from 'react';

const navLinks = [
  { href: '#about', label: 'About' },
  { href: '#value', label: 'Value' },
  { href: '#skills', label: 'Skills' },
  { href: '#projects', label: 'Projects' },
  { href: '#architecture', label: 'Architecture' },
  { href: '#approach', label: 'Approach' },
  { href: '#contact', label: 'Contact' },
];

const Navbar = () => {
  const [scrolled, setScrolled] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 40);
    window.addEventListener('scroll', onScroll);
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  return (
    <nav
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        scrolled ? 'bg-navy/95 backdrop-blur-md border-b border-cyan/20 shadow-lg' : 'bg-transparent'
      }`}
    >
      <div className="container flex items-center justify-between py-4">
        <a href="#top" className="flex items-center gap-3 group" aria-label="Olatunbosun Ibiyinka — home">
          <img
            src="/profile.jpg"
            alt=""
            className="w-10 h-10 rounded-full object-cover border-2 border-cyan/40 group-hover:border-cyan shadow-md group-hover:shadow-cyan/20 transition-all duration-300"
          />
          <span className="text-sm font-bold gradient-text tracking-wide">
            OI
          </span>
        </a>

        <div className="hidden md:flex items-center gap-8">
          {navLinks.map((link) => (
            <a
              key={link.href}
              href={link.href}
              className="text-sm text-gray-300 hover:text-cyan transition-colors duration-200"
            >
              {link.label}
            </a>
          ))}
        </div>

        <button
          type="button"
          className="md:hidden text-cyan"
          onClick={() => setMenuOpen(!menuOpen)}
          aria-label="Toggle menu"
        >
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            {menuOpen ? (
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            ) : (
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
            )}
          </svg>
        </button>
      </div>

      {menuOpen && (
        <div className="md:hidden border-t border-cyan/20 bg-navy/98 backdrop-blur-md">
          <div className="container py-4 flex flex-col gap-4">
            {navLinks.map((link) => (
              <a
                key={link.href}
                href={link.href}
                className="text-gray-300 hover:text-cyan transition-colors"
                onClick={() => setMenuOpen(false)}
              >
                {link.label}
              </a>
            ))}
          </div>
        </div>
      )}
    </nav>
  );
};

export default Navbar;
