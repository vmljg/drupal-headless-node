import { useState, useEffect } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/router'
import { siteApi } from '../lib/api'

const Header = ({ siteConfig, menu }) => {
  const router = useRouter()
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)

  return (
    <header className="bg-white shadow-sm border-b border-gray-200">
      <div className="content-container">
        <div className="flex justify-between items-center py-4">
          {/* Logo and site name */}
          <div className="flex items-center">
            <Link href="/" className="flex items-center space-x-2">
              <div className="w-8 h-8 bg-primary-600 rounded-lg flex items-center justify-center">
                <span className="text-white font-bold text-lg">
                  {siteConfig?.site?.name?.charAt(0) || 'H'}
                </span>
              </div>
              <span className="text-xl font-semibold text-gray-900">
                {siteConfig?.site?.name || 'Headless Site'}
              </span>
            </Link>
          </div>

          {/* Desktop navigation */}
          <nav className="hidden md:flex space-x-8">
            <Link 
              href="/" 
              className={`text-sm font-medium transition-colors ${
                router.pathname === '/' 
                  ? 'text-primary-600' 
                  : 'text-gray-700 hover:text-primary-600'
              }`}
            >
              Home
            </Link>
            <Link 
              href="/articles" 
              className={`text-sm font-medium transition-colors ${
                router.pathname.startsWith('/articles') 
                  ? 'text-primary-600' 
                  : 'text-gray-700 hover:text-primary-600'
              }`}
            >
              Articles
            </Link>
            <Link 
              href="/pages" 
              className={`text-sm font-medium transition-colors ${
                router.pathname.startsWith('/pages') 
                  ? 'text-primary-600' 
                  : 'text-gray-700 hover:text-primary-600'
              }`}
            >
              Pages
            </Link>
            <Link 
              href="/search" 
              className={`text-sm font-medium transition-colors ${
                router.pathname === '/search' 
                  ? 'text-primary-600' 
                  : 'text-gray-700 hover:text-primary-600'
              }`}
            >
              Search
            </Link>
          </nav>

          {/* Mobile menu button */}
          <button
            className="md:hidden p-2 rounded-md text-gray-700 hover:text-primary-600 hover:bg-gray-100"
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              {mobileMenuOpen ? (
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              ) : (
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
              )}
            </svg>
          </button>
        </div>

        {/* Mobile navigation */}
        {mobileMenuOpen && (
          <div className="md:hidden py-4 border-t border-gray-200">
            <nav className="flex flex-col space-y-4">
              <Link 
                href="/" 
                className={`text-sm font-medium ${
                  router.pathname === '/' 
                    ? 'text-primary-600' 
                    : 'text-gray-700'
                }`}
                onClick={() => setMobileMenuOpen(false)}
              >
                Home
              </Link>
              <Link 
                href="/articles" 
                className={`text-sm font-medium ${
                  router.pathname.startsWith('/articles') 
                    ? 'text-primary-600' 
                    : 'text-gray-700'
                }`}
                onClick={() => setMobileMenuOpen(false)}
              >
                Articles
              </Link>
              <Link 
                href="/pages" 
                className={`text-sm font-medium ${
                  router.pathname.startsWith('/pages') 
                    ? 'text-primary-600' 
                    : 'text-gray-700'
                }`}
                onClick={() => setMobileMenuOpen(false)}
              >
                Pages
              </Link>
              <Link 
                href="/search" 
                className={`text-sm font-medium ${
                  router.pathname === '/search' 
                    ? 'text-primary-600' 
                    : 'text-gray-700'
                }`}
                onClick={() => setMobileMenuOpen(false)}
              >
                Search
              </Link>
            </nav>
          </div>
        )}
      </div>
    </header>
  )
}

const Footer = ({ siteConfig }) => {
  return (
    <footer className="bg-gray-900 text-white">
      <div className="content-container py-12">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {/* Site info */}
          <div>
            <h3 className="text-lg font-semibold mb-4">
              {siteConfig?.site?.name || 'Headless Site'}
            </h3>
            <p className="text-gray-300 text-sm">
              {siteConfig?.site?.description || 'A modern headless CMS solution with Drupal, Platformatic, and Next.js'}
            </p>
          </div>

          {/* Quick links */}
          <div>
            <h3 className="text-lg font-semibold mb-4">Quick Links</h3>
            <ul className="space-y-2 text-sm">
              <li>
                <Link href="/" className="text-gray-300 hover:text-white transition-colors">
                  Home
                </Link>
              </li>
              <li>
                <Link href="/articles" className="text-gray-300 hover:text-white transition-colors">
                  Articles
                </Link>
              </li>
              <li>
                <Link href="/pages" className="text-gray-300 hover:text-white transition-colors">
                  Pages
                </Link>
              </li>
              <li>
                <Link href="/search" className="text-gray-300 hover:text-white transition-colors">
                  Search
                </Link>
              </li>
            </ul>
          </div>

          {/* Technical info */}
          <div>
            <h3 className="text-lg font-semibold mb-4">Powered By</h3>
            <ul className="space-y-2 text-sm text-gray-300">
              <li>Drupal (Headless CMS)</li>
              <li>Platformatic PHP-Node</li>
              <li>Next.js Frontend</li>
              <li>Tailwind CSS</li>
            </ul>
          </div>
        </div>

        <div className="border-t border-gray-800 mt-8 pt-8 text-center text-sm text-gray-400">
          <p>
            &copy; {new Date().getFullYear()} {siteConfig?.site?.name || 'Headless Site'}. 
            Built with ❤️ using modern web technologies.
          </p>
        </div>
      </div>
    </footer>
  )
}

const Layout = ({ children, title, description }) => {
  const [siteConfig, setSiteConfig] = useState(null)
  const [menu, setMenu] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const loadSiteData = async () => {
      try {
        const [configData, menuData] = await Promise.all([
          siteApi.getConfig(),
          siteApi.getMenu('main').catch(() => null) // Menu might not exist
        ])
        
        setSiteConfig(configData)
        setMenu(menuData)
      } catch (error) {
        console.error('Failed to load site data:', error)
      } finally {
        setLoading(false)
      }
    }

    loadSiteData()
  }, [])

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="loading-spinner w-8 h-8 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen flex flex-col">
      <Header siteConfig={siteConfig} menu={menu} />
      
      <main className="flex-1">
        {children}
      </main>
      
      <Footer siteConfig={siteConfig} />
    </div>
  )
}

export default Layout

