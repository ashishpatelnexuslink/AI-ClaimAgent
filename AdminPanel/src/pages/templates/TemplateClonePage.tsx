import { useEffect, useRef } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import Spinner from '../../components/ui/Spinner';
import { useCloneTemplate } from '../../hooks/useTemplates';
import { useToastContext } from '../../hooks/ToastContext';

/**
 * /templates/:id/clone — fires the clone mutation on mount and redirects to
 * /templates/:newId/edit. If cloning fails we bounce back to the source detail page.
 */
export default function TemplateClonePage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { addToast } = useToastContext();
  const clone = useCloneTemplate();
  const firedRef = useRef(false);

  useEffect(() => {
    if (firedRef.current || !id) return;
    firedRef.current = true;

    clone.mutate(id, {
      onSuccess: (tpl) => {
        addToast(`Cloned to v${tpl.version} draft`, 'success');
        navigate(`/templates/${tpl.id}/edit`, { replace: true });
      },
      onError: () => {
        addToast('Failed to clone template', 'error');
        navigate('/templates', { replace: true });
      },
    });
  }, [id, clone, addToast, navigate]);

  return (
    <div className="flex flex-col items-center justify-center min-h-[400px]">
      <Spinner size="lg" />
      <p className="text-sm text-gray-500 mt-3">Cloning template…</p>
    </div>
  );
}
