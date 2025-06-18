import { useState, useEffect } from 'react'
import Head from 'next/head'
import Link from 'next/link'
import Layout from '../components/Layout'
import { contentApi, siteApi, apiUtils } from '../lib/api'

const FeaturedContent = ({ content }) => {
  if (!content || (!content.articles?.length && !content.pages?.length)) {
    return null
  }

  return (
    <section className="py-12 bg-white">
      <div className="content-container">
        <h2 className="text-3xl font-bold text-gray-900 mb-8">Featured Content</h2>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {/* Featured Articles */}
          {content.articles?.map((article) => (
            <article key={article.id} className="card hover:shadow-md transition-shadow">
              <div className="card-body">
                <h3 className="text-xl font-semibold text-gray-900 mb-2">
                  <Link 
                    href={`/articles/${article.id}`}
                    className="hover:text-primary-600 transition-colors"
                  >
                    {article.attributes.title}
                  </Link>
                </h3>
                
                {article.attributes.body && (
                  <p className="text-gray-600 text-sm mb-4 line-clamp-3">
                    {apiUtils.extractText(article.attributes.body).substring(0, 150)}...
                  </p>
                )}
                
                <div className="flex items-center justify-between text-sm text-gray-500">
                  <span>Article</span>
                  <time dateTime={article.attributes.created}>
                    {apiUtils.formatDate(article.attributes.created)}
                  </time>
                </div>
              </div>
            </article>
          ))}
          
          {/* Featured Pages */}
          {content.pages?.map((page) => (
            <article key={page.id} className="card hover:shadow-md transition-shadow">
              <div className="card-body">
                <h3 className="text-xl font-semibold text-gray-900 mb-2">
                  <Link 
                    href={`/pages/${page.id}`}
                    className="hover:text-primary-600 transition-colors"
                  >
                    {page.attributes.title}
                  </Link>
                </h3>
                
                {page.attributes.body && (
                  <p className="text-gray-600 text-sm mb-4 line-clamp-3">
                    {apiUtils.extractText(page.attributes.body).substring(0, 150)}...
                  </p>
                )}
                
                <div className="flex items-center justify-between text-sm text-gray-500">
                  <span>Page</span>
                  <time dateTime={page.attributes.created}>
                    {apiUtils.formatDate(page.attributes.created)}
                  </time>
                </div>
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  )
}

const StatsSection = ({ stats }) => {
  if (!stats) return null

  return (
    <section className="py-12 bg-gray-50">
      <div className="content-container">
        <h2 className="text-3xl font-bold text-gray-900 mb-8 text-center">Site Statistics</h2>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <div className="card text-center">
            <div className="card-body">
              <div className="text-3xl font-bold text-primary-600 mb-2">
                {stats.content?.total_nodes || 0}
              </div>
              <div className="text-sm text-gray-600">Total Content</div>
            </div>
          </div>
          
          <div className="card text-center">
            <div className="card-body">
              <div className="text-3xl font-bold text-primary-600 mb-2">
                {stats.content?.articles || 0}
              </div>
              <div className="text-sm text-gray-600">Articles</div>
            </div>
          </div>
          
          <div className="card text-center">
            <div className="card-body">
              <div className="text-3xl font-bold text-primary-600 mb-2">
                {stats.content?.pages || 0}
              </div>
              <div className="text-sm text-gray-600">Pages</div>
            </div>
          </div>
          
          <div className="card text-center">
            <div className="card-body">
              <div className="text-3xl font-bold text-primary-600 mb-2">
                {Math.round((stats.api?.cache_hit_rate || 0) * 100)}%
              </div>
              <div className="text-sm text-gray-600">Cache Hit Rate</div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}

const HeroSection = ({ siteConfig }) => {
  return (
    <section className="bg-gradient-to-r from-primary-600 to-primary-800 text-white py-20">
      <div className="content-container text-center">
        <h1 className="text-4xl md:text-6xl font-bold mb-6">
          {siteConfig?.site?.name || 'Headless Drupal Site'}
        </h1>
        <p className="text-xl md:text-2xl text-primary-100 mb-8 max-w-3xl mx-auto">
          {siteConfig?.site?.description || 'Modern headless CMS powered by Drupal, Platformatic PHP-Node, and Next.js'}
        </p>
        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <Link href="/articles" className="btn-secondary">
            Browse Articles
          </Link>
          <Link href="/search" className="btn-outline border-white text-white hover:bg-white hover:text-primary-600">
            Search Content
          </Link>
        </div>
      </div>
    </section>
  )
}

const TechStack = () => {
  const technologies = [
    {
      name: 'Drupal',
      description: 'Headless CMS providing content management and JSON:API',
      icon: '🏗️'
    },
    {
      name: 'Platformatic PHP-Node',
      description: 'Bridge layer connecting PHP and Node.js in the same process',
      icon: '🌉'
    },
    {
      name: 'Next.js',
      description: 'React framework for server-side rendering and static generation',
      icon: '⚛️'
    },
    {
      name: 'Tailwind CSS',
      description: 'Utility-first CSS framework for rapid UI development',
      icon: '🎨'
    }
  ]

  return (
    <section className="py-16 bg-white">
      <div className="content-container">
        <h2 className="text-3xl font-bold text-gray-900 mb-8 text-center">Technology Stack</h2>
        <p className="text-lg text-gray-600 text-center mb-12 max-w-3xl mx-auto">
          This application demonstrates the power of modern headless architecture, 
          combining the best of PHP and Node.js ecosystems.
        </p>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
          {technologies.map((tech) => (
            <div key={tech.name} className="text-center">
              <div className="text-4xl mb-4">{tech.icon}</div>
              <h3 className="text-xl font-semibold text-gray-900 mb-2">{tech.name}</h3>
              <p className="text-gray-600 text-sm">{tech.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

export default function Home() {
  const [featuredContent, setFeaturedContent] = useState(null)
  const [siteConfig, setSiteConfig] = useState(null)
  const [stats, setStats] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    const loadData = async () => {
      try {
        const [featured, config, siteStats] = await Promise.all([
          contentApi.getFeaturedContent(),
          siteApi.getConfig(),
          siteApi.getStats().catch(() => null) // Stats might not be available
        ])
        
        setFeaturedContent(featured)
        setSiteConfig(config)
        setStats(siteStats)
      } catch (err) {
        console.error('Failed to load home page data:', err)
        setError(apiUtils.handleError(err))
      } finally {
        setLoading(false)
      }
    }

    loadData()
  }, [])

  if (loading) {
    return (
      <Layout>
        <div className="min-h-screen flex items-center justify-center">
          <div className="text-center">
            <div className="loading-spinner w-8 h-8 mx-auto mb-4"></div>
            <p className="text-gray-600">Loading content...</p>
          </div>
        </div>
      </Layout>
    )
  }

  if (error) {
    return (
      <Layout>
        <div className="min-h-screen flex items-center justify-center">
          <div className="text-center">
            <div className="text-red-500 text-6xl mb-4">⚠️</div>
            <h1 className="text-2xl font-bold text-gray-900 mb-2">Unable to Load Content</h1>
            <p className="text-gray-600 mb-4">{error.message}</p>
            <button 
              onClick={() => window.location.reload()} 
              className="btn-primary"
            >
              Try Again
            </button>
          </div>
        </div>
      </Layout>
    )
  }

  return (
    <Layout>
      <Head>
        <title>{siteConfig?.site?.name || 'Headless Drupal Site'}</title>
        <meta 
          name="description" 
          content={siteConfig?.site?.description || 'Modern headless CMS with Drupal, Platformatic, and Next.js'} 
        />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <HeroSection siteConfig={siteConfig} />
      <FeaturedContent content={featuredContent} />
      <StatsSection stats={stats} />
      <TechStack />
    </Layout>
  )
}

