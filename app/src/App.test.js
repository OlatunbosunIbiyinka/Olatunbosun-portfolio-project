import { render, screen } from '@testing-library/react';
import App from './App';

describe('App', () => {
  it('renders the hero headline', () => {
    render(<App />);
    expect(screen.getAllByText(/Platform \/ DevOps Engineer/i).length).toBeGreaterThan(0);
    expect(screen.getByRole('heading', { name: /Olatunbosun/i })).toBeInTheDocument();
  });

  it('renders primary navigation links', () => {
    render(<App />);
    expect(screen.getByRole('link', { name: /about/i })).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /contact/i })).toBeInTheDocument();
  });
});
