import { useState, useEffect } from 'react'
import Head from 'next/head'
import Link from 'next/link'
import { useRouter } from 'next/router'
import Layout from '../components/Layout'
import { contentApi, apiUtils } from '../lib/api'

const ArticleCard = ({ article }) => {
  return (
    <article className="card hover:shadow-md transition-shadow">
      <div className="card-body">
        <h2 className="text-xl font-semibold text-gray-900 mb-3">
          <Link 
            href={`/articles/${article.id}`}
            className="hover:text-primary-600 transition-colors"
          >
            {article.attributes.title}
          </Link>
        </h2>
        
        {article.attributes.body && (
          <p className="text-gray-600 mb-4 line-clamp-3">
            {apiUtils.extractText(article.attributes.body).substring(0, 200)}...
          </p>
        )}
        
        <div className="flex items-center justify-between text-sm text-gray-500">
          <div className="flex items-center space-x-4">
            {article.attributes.uid && (
              <span>By {article.attributes.uid.data?.attributes?.name || 'Anonymous'}</span>
            )}
            <time dateTime={article.attributes.created}>
              {apiUtils.formatDate(article.attributes.created)}
            </time>
          </div>
          
          {article.attributes.field_tags && (
            <div className="flex flex-wrap gap-1">
              {article.attributes.field_tags.data?.slice(0, 2).map((tag) => (
                <span 
                  key={tag.id}
                  className="inline-block px-2 py-1 text-xs bg-primary-100 text-primary-800 rounded"
                >
                  {tag.attributes.name}
                </span>
              ))}
            </div>
          )}
        </div>
        
        <div className="mt-4">
          <Link 
            href={`/articles/${article.id}`}
            className="text-primary-600 hover:text-primary-800 text-sm font-medium"
          >
            Read more →
          </Link>
        </div>
      </div>
    </article>
  )
}

const Pagination = ({ currentPage, totalPages, onPageChange }) => {
  const pages = []
  const maxVisiblePages = 5
  
  let startPage = Math.max(1, currentPage - Math.floor(maxVisiblePages / 2))
  let endPage = Math.min(totalPages, startPage + maxVisiblePages - 1)
  
  if (endPage - startPage + 1 < maxVisiblePages) {
    startPage = Math.max(1, endPage - maxVisiblePages + 1)
  }
  
  for (let i = startPage; i <= endPage; i++) {
    pages.push(i)
  }

  return (
    <div className="flex items-center justify-center space-x-2 mt-8">
      <button
        onClick={() => onPageChange(currentPage - 1)}
        disabled={currentPage <= 1}
        className="px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        Previous
      </button>
      
      {pages.map((page) => (
        <button
          key={page}
          onClick={() => onPageChange(page)}
          className={`px-3 py-2 text-sm font-medium rounded-md ${
            page === currentPage
              ? 'text-white bg-primary-600 border border-primary-600'
              : 'text-gray-700 bg-white border border-gray-300 hover:bg-gray-50'
          }`}
        >
          {page}
        </button>
      ))}
      
      <button
        onClick={() => onPageChange(currentPage + 1)}
        disabled={currentPage >= totalPages}
        className="px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        Next
      </button>
    </div>
  )
}

const FilterBar = ({ sortBy, setSortBy, filterBy, setFilterBy }) => {
  return (
    <div className="bg-white border border-gray-200 rounded-lg p-4 mb-6">
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="flex-1">
          <label htmlFor="sort" className="form-label">Sort by</label>
          <select
            id="sort"
            value={sortBy}
            onChange={(e) => setSortBy(e.target.value)}
            className="form-input"
          >
            <option value="-created">Newest first</option>
            <option value="created">Oldest first</option>
            <option value="title">Title A-Z</option>
            <option value="-title">Title Z-A</option>
          </select>
        </div>
        
        <div className="flex-1">
          <label htmlFor="filter" className="form-label">Filter by status</label>
          <select
            id="filter"
            value={filterBy}
            onChange={(e) => setFilterBy(e.target.value)}
            className="form-input"
          >
            <option value="">All articles</option>
            <option value="published">Published only</option>
            <option value="promoted">Featured articles</option>
          </select>
        </div>
      </div>
    </div>
  )
}

export default function Articles() {
  const router = useRouter()
  const [articles, setArticles] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [currentPage, setCurrentPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)
  const [sortBy, setSortBy] = useState('-created')
  const [filterBy, setFilterBy] = useState('')
  
  const itemsPerPage = 9

  useEffect(() => {
    const loadArticles = async () => {
      setLoading(true)
      setError(null)
      
      try {
        const filters = {
          'page[limit]': itemsPerPage,
          'page[offset]': (currentPage - 1) * itemsPerPage,
          'sort': sortBy,
          'include': 'uid,field_tags'
        }
        
        // Add status filter if selected
        if (filterBy === 'published') {
          filters['filter[status]'] = 1
        } else if (filterBy === 'promoted') {
          filters['filter[promote]'] = 1
        }
        
        const response = await contentApi.getContent('article', filters)
        
        setArticles(response.data || [])
        
        // Calculate total pages from meta information
        if (response.meta && response.meta.count) {
          setTotalPages(Math.ceil(response.meta.count / itemsPerPage))
        }
        
      } catch (err) {
        console.error('Failed to load articles:', err)
        setError(apiUtils.handleError(err))
      } finally {
        setLoading(false)
      }
    }

    loadArticles()
  }, [currentPage, sortBy, filterBy])

  const handlePageChange = (page) => {
    setCurrentPage(page)
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  return (
    <Layout>
      <Head>
        <title>Articles - Headless Drupal Site</title>
        <meta name="description" content="Browse all articles from our headless Drupal CMS" />
      </Head>

      <div className="page-header py-8">
        <div className="content-container">
          <h1 className="page-title">Articles</h1>
          <p className="page-subtitle">
            Explore our collection of articles powered by headless Drupal
          </p>
        </div>
      </div>

      <div className="content-container py-8">
        <FilterBar 
          sortBy={sortBy}
          setSortBy={setSortBy}
          filterBy={filterBy}
          setFilterBy={setFilterBy}
        />

        {loading && (
          <div className="text-center py-12">
            <div className="loading-spinner w-8 h-8 mx-auto mb-4"></div>
            <p className="text-gray-600">Loading articles...</p>
          </div>
        )}

        {error && (
          <div className="text-center py-12">
            <div className="text-red-500 text-4xl mb-4">⚠️</div>
            <h2 className="text-xl font-semibold text-gray-900 mb-2">Failed to Load Articles</h2>
            <p className="text-gray-600 mb-4">{error.message}</p>
            <button 
              onClick={() => window.location.reload()} 
              className="btn-primary"
            >
              Try Again
            </button>
          </div>
        )}

        {!loading && !error && articles.length === 0 && (
          <div className="text-center py-12">
            <div className="text-gray-400 text-4xl mb-4">📝</div>
            <h2 className="text-xl font-semibold text-gray-900 mb-2">No Articles Found</h2>
            <p className="text-gray-600">
              {filterBy ? 'Try adjusting your filters to see more results.' : 'No articles have been published yet.'}
            </p>
          </div>
        )}

        {!loading && !error && articles.length > 0 && (
          <>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {articles.map((article) => (
                <ArticleCard key={article.id} article={article} />
              ))}
            </div>

            {totalPages > 1 && (
              <Pagination
                currentPage={currentPage}
                totalPages={totalPages}
                onPageChange={handlePageChange}
              />
            )}
          </>
        )}
      </div>
    </Layout>
  )
}

