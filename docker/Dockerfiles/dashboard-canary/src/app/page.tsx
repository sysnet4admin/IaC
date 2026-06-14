'use client';
import Image from 'next/image'
import Banner from '../../public/argo.webp';
import dynamic from 'next/dynamic';
import ghIcon from '../../public/github.svg';
import LinkedinMenu from './components/LinkedinMenu';
import canaryV1 from '../../public/canary_v1.json';
import canaryV2 from '../../public/canary_v2.json';

const Player = dynamic(
  () => import('@lottiefiles/react-lottie-player').then(m => m.Player),
  { ssr: false }
);

const phase = process.env.NEXT_PUBLIC_PHASE;

const authors = [
  {'name': 'Hoon Jo', url: 'https://www.linkedin.com/in/hoonjo/'},
  {'name': 'Gnu Shim', url: 'https://www.linkedin.com/in/gnu-shim/'},
  {'name': 'Seongju Mun', url: 'https://www.linkedin.com/in/seongjuishere/'},
  {'name': 'Sungmin Lee', url: 'https://www.linkedin.com/in/sungmincs/'},
]

export default function Home() {
  return (
  <div className="flex flex-col justify-center items-center w-full h-full content-center">
    <header className='flex-0 w-full bg-white border-b border-gray-200 body-font'>
      <div className="container mx-auto flex flex-wrap p-5 flex-col md:flex-row items-center">
          <div className="flex title-font font-medium items-center text-gray-900 mb-4 md:mb-0">
            <Image src={Banner} alt="banner" className="w-10 h-10 mr-1" />
            <span className={`ml-3 text-xl text-${phase}-500`}>아르고 롤아웃 체험하기</span>
          </div>
          <nav className="md:ml-auto flex flex-wrap items-center text-base justify-center">
            <div className="mr-5 hover:text-gray-900">
              <LinkedinMenu data={authors} />
            </div>
            <div className="mr-2 hover:text-gray-900">
              <a className='flex items-center py-5 px-2 text-gray-900' href='https://github.com/sysnet4admin/_book_k8sinfra'>
                <Image src={ghIcon} alt="github" className="w-6 h-6 mr-2" />Github
              </a>
            </div>
          </nav>
      </div>
    </header>
    <div className={`font-sans text-7xl p-4 m-6 text-${phase}-700 basis-1/8`}>
      Hello Canary!
    </div>
    <div className='flex justify-center items-center flex-1'>
      {phase === 'v1' && <Player autoplay loop src={canaryV1 as object} style={{ height: '300px', width: '300px' }}/>}
      {phase === 'v2' && <Player autoplay loop src={canaryV2 as object} style={{ height: '300px', width: '300px' }}/>}
    </div>
  </div>
  );
}
