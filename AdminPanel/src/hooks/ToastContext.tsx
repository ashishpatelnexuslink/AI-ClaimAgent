import { createContext, useContext, type ReactNode } from 'react';
import { useToast } from './useToast';
import { X, CheckCircle, AlertCircle, Info } from 'lucide-react';

interface ToastContextType {
  addToast: (message: string, type?: 'success' | 'error' | 'info') => void;
}

const ToastContext = createContext<ToastContextType>({ addToast: () => {} });

export function useToastContext() {
  return useContext(ToastContext);
}

export function ToastProvider({ children }: { children: ReactNode }) {
  const { toasts, addToast, removeToast } = useToast();

  return (
    <ToastContext.Provider value={{ addToast }}>
      {children}
      <div className="fixed top-4 right-4 z-[100] flex flex-col gap-2">
        {toasts.map((toast) => (
          <div
            key={toast.id}
            className={`flex items-center gap-3 rounded-xl px-4 py-3 text-white shadow-lg min-w-[300px] animate-[slideIn_0.3s_ease] ${
              toast.type === 'success' ? 'bg-success' :
              toast.type === 'error' ? 'bg-danger' : 'bg-primary'
            }`}
          >
            {toast.type === 'success' ? <CheckCircle size={18} /> :
             toast.type === 'error' ? <AlertCircle size={18} /> :
             <Info size={18} />}
            <span className="flex-1 text-sm font-medium">{toast.message}</span>
            <button onClick={() => removeToast(toast.id)} className="hover:opacity-70">
              <X size={16} />
            </button>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}
