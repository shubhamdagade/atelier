import { useEffect, useState } from 'react';
import Layout from '../components/Layout';
import { Loader, Plus } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { apiFetchJson } from '../lib/api';

export default function VendorDashboard() {
  const [loading, setLoading] = useState(true);
  const [projects, setProjects] = useState([]);
  const [summary, setSummary] = useState({});
  const [error, setError] = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    fetchData();
  }, []);

  async function fetchData() {
    try {
      setLoading(true);
      const pData = await apiFetchJson('/api/projects');
      setProjects(pData);

      // Fetch MAS summary (counts grouped by project)
      const sData = await apiFetchJson('/api/mas/summary');

      // Convert summary array to map by project id
      const map = {};
      sData.forEach(row => {
        map[row.project_id] = {
          pending: parseInt(row.pending_count || 0),
          approved: parseInt(row.approved_count || 0),
          total: parseInt(row.total_count || 0)
        };
      });
      setSummary(map);
    } catch (err) {
      console.error(err);
      setError(err.message || 'Failed to load dashboard');
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return (
      <Layout>
        <div className="flex items-center justify-center py-12">
          <Loader className="w-8 h-8 text-lodha-gold animate-spin" />
        </div>
      </Layout>
    );
  }

  return (
    <Layout>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="heading-primary">Vendor Dashboard</h1>
          <p className="text-body">Summary of Material Approval Sheets you have sent</p>
        </div>
        <div>
          <button
            onClick={() => navigate('/mas?create=true')}
            className="inline-flex items-center gap-2 px-4 py-2 bg-lodha-gold hover:bg-lodha-deep text-white rounded-md shadow"
          >
            <Plus className="w-4 h-4" />
            Create New MAS
          </button>
        </div>
      </div>

      {error && (
        <div className="bg-lodha-sand border border-lodha-gold rounded-lg p-4 text-lodha-black mb-6">
          {error}
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {projects.map(proj => {
          const counts = summary[proj.id] || { pending: 0, approved: 0, total: 0 };
          return (
            <div key={proj.id} className="p-4 bg-white rounded-lg shadow-sm">
              <div className="flex items-center justify-between mb-2">
                <h2 className="text-lg font-garamond font-bold text-lodha-gold">{proj.name}</h2>
                <div className="text-sm text-lodha-grey">{proj.lifecycle_stage}</div>
              </div>
              <p className="text-sm text-lodha-grey mb-4">{proj.description}</p>

              <div className="flex gap-3">
                <div className="flex-1 p-3 bg-lodha-sand rounded-md text-center">
                  <div className="text-xl font-garamond text-lodha-gold">{counts.total}</div>
                  <div className="text-sm text-lodha-grey">Total MAS</div>
                </div>
                <div className="flex-1 p-3 bg-lodha-sand rounded-md text-center">
                  <div className="text-xl font-garamond text-lodha-gold">{counts.pending}</div>
                  <div className="text-sm text-lodha-grey">Pending</div>
                </div>
                <div className="flex-1 p-3 bg-lodha-sand rounded-md text-center">
                  <div className="text-xl font-garamond text-lodha-gold">{counts.approved}</div>
                  <div className="text-sm text-lodha-grey">Approved</div>
                </div>
              </div>

              <div className="mt-4">
                <button
                  onClick={() => navigate(`/mas?projectId=${proj.id}`)}
                  className="px-3 py-1 bg-lodha-gold text-white rounded-md"
                >
                  View MAS
                </button>
              </div>
            </div>
          );
        })}
      </div>
    </Layout>
  );
}
